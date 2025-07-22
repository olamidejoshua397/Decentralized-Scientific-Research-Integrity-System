;; Open Science Collaboration Contract
;; Facilitates global scientific collaboration and data sharing

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-NOT-FOUND (err u103))
(define-constant ERR-PROJECT-FULL (err u105))

;; Data Variables
(define-data-var next-project-id uint u1)
(define-data-var next-contribution-id uint u1)
(define-data-var next-resource-id uint u1)

;; Data Maps
(define-map collaboration-projects
  { project-id: uint }
  {
    title: (string-utf8 256),
    description: (string-utf8 1024),
    lead-researcher: principal,
    created-at: uint,
    status: (string-ascii 32),
    max-collaborators: uint,
    current-collaborators: uint,
    research-field: (string-ascii 64),
    is-open: bool
  }
)

(define-map project-collaborators
  { project-id: uint, collaborator: principal }
  {
    joined-at: uint,
    role: (string-ascii 32),
    contribution-score: uint,
    is-active: bool
  }
)

(define-map contributions
  { contribution-id: uint }
  {
    project-id: uint,
    contributor: principal,
    contribution-type: (string-ascii 32),
    description: (string-utf8 512),
    resource-hash: (buff 32),
    submitted-at: uint,
    is-verified: bool,
    impact-score: uint
  }
)

(define-map shared-resources
  { resource-id: uint }
  {
    project-id: uint,
    owner: principal,
    resource-type: (string-ascii 32),
    title: (string-utf8 128),
    description: (string-utf8 512),
    access-level: (string-ascii 32),
    usage-count: uint,
    shared-at: uint
  }
)

(define-map researcher-profiles
  { researcher: principal }
  {
    name: (string-utf8 128),
    institution: (string-utf8 128),
    research-fields: (string-ascii 128),
    collaboration-score: uint,
    total-contributions: uint,
    active-projects: uint,
    last-active: uint
  }
)

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? collaboration-projects { project-id: project-id })
)

(define-read-only (get-project-collaborator (project-id uint) (collaborator principal))
  (map-get? project-collaborators { project-id: project-id, collaborator: collaborator })
)

(define-read-only (get-contribution (contribution-id uint))
  (map-get? contributions { contribution-id: contribution-id })
)

(define-read-only (get-shared-resource (resource-id uint))
  (map-get? shared-resources { resource-id: resource-id })
)

(define-read-only (get-researcher-profile (researcher principal))
  (map-get? researcher-profiles { researcher: researcher })
)

(define-read-only (is-project-collaborator (project-id uint) (researcher principal))
  (match (get-project-collaborator project-id researcher)
    collaborator-data (get is-active collaborator-data)
    false
  )
)

(define-read-only (calculate-collaboration-score (total-contributions uint) (active-projects uint) (impact-score uint))
  (+ (* total-contributions u5) (* active-projects u10) (* impact-score u2))
)

;; Public functions
(define-public (create-project
  (title (string-utf8 256))
  (description (string-utf8 1024))
  (max-collaborators uint)
  (research-field (string-ascii 64))
)
  (let
    (
      (current-id (var-get next-project-id))
      (lead-researcher tx-sender)
      (current-time block-height)
    )
    ;; Input validation
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= max-collaborators u2) (<= max-collaborators u50)) ERR-INVALID-INPUT)
    (asserts! (> (len research-field) u0) ERR-INVALID-INPUT)

    ;; Store project
    (map-set collaboration-projects
      { project-id: current-id }
      {
        title: title,
        description: description,
        lead-researcher: lead-researcher,
        created-at: current-time,
        status: "active",
        max-collaborators: max-collaborators,
        current-collaborators: u1,
        research-field: research-field,
        is-open: true
      }
    )

    ;; Add lead researcher as collaborator
    (map-set project-collaborators
      { project-id: current-id, collaborator: lead-researcher }
      {
        joined-at: current-time,
        role: "lead",
        contribution-score: u0,
        is-active: true
      }
    )

    ;; Update researcher profile
    (update-researcher-profile-for-project lead-researcher)

    ;; Increment next ID
    (var-set next-project-id (+ current-id u1))

    (ok current-id)
  )
)

(define-public (join-project (project-id uint) (role (string-ascii 32)))
  (let
    (
      (collaborator tx-sender)
      (current-time block-height)
      (project-data (unwrap! (get-project project-id) ERR-NOT-FOUND))
    )
    ;; Input validation
    (asserts! (> (len role) u0) ERR-INVALID-INPUT)
    (asserts! (get is-open project-data) ERR-NOT-AUTHORIZED)
    (asserts! (< (get current-collaborators project-data) (get max-collaborators project-data)) ERR-PROJECT-FULL)
    (asserts! (not (is-project-collaborator project-id collaborator)) ERR-ALREADY-EXISTS)

    ;; Add collaborator
    (map-set project-collaborators
      { project-id: project-id, collaborator: collaborator }
      {
        joined-at: current-time,
        role: role,
        contribution-score: u0,
        is-active: true
      }
    )

    ;; Update project collaborator count
    (map-set collaboration-projects
      { project-id: project-id }
      (merge project-data { current-collaborators: (+ (get current-collaborators project-data) u1) })
    )

    ;; Update researcher profile
    (update-researcher-profile-for-project collaborator)

    (ok true)
  )
)

(define-public (submit-contribution
  (project-id uint)
  (contribution-type (string-ascii 32))
  (description (string-utf8 512))
  (resource-hash (buff 32))
)
  (let
    (
      (current-id (var-get next-contribution-id))
      (contributor tx-sender)
      (current-time block-height)
    )
    ;; Input validation
    (asserts! (> (len contribution-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (is-project-collaborator project-id contributor) ERR-NOT-AUTHORIZED)

    ;; Store contribution
    (map-set contributions
      { contribution-id: current-id }
      {
        project-id: project-id,
        contributor: contributor,
        contribution-type: contribution-type,
        description: description,
        resource-hash: resource-hash,
        submitted-at: current-time,
        is-verified: false,
        impact-score: u0
      }
    )

    ;; Update collaborator contribution score
    (match (get-project-collaborator project-id contributor)
      collaborator-data
        (map-set project-collaborators
          { project-id: project-id, collaborator: contributor }
          (merge collaborator-data { contribution-score: (+ (get contribution-score collaborator-data) u10) })
        )
      false
    )

    ;; Update researcher profile
    (update-researcher-profile-for-contribution contributor)

    ;; Increment next ID
    (var-set next-contribution-id (+ current-id u1))

    (ok current-id)
  )
)

(define-public (share-resource
  (project-id uint)
  (resource-type (string-ascii 32))
  (title (string-utf8 128))
  (description (string-utf8 512))
  (access-level (string-ascii 32))
)
  (let
    (
      (current-id (var-get next-resource-id))
      (owner tx-sender)
      (current-time block-height)
    )
    ;; Input validation
    (asserts! (> (len resource-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (is-project-collaborator project-id owner) ERR-NOT-AUTHORIZED)

    ;; Store resource
    (map-set shared-resources
      { resource-id: current-id }
      {
        project-id: project-id,
        owner: owner,
        resource-type: resource-type,
        title: title,
        description: description,
        access-level: access-level,
        usage-count: u0,
        shared-at: current-time
      }
    )

    ;; Increment next ID
    (var-set next-resource-id (+ current-id u1))

    (ok current-id)
  )
)

(define-public (verify-contribution (contribution-id uint) (impact-score uint))
  (let
    (
      (contribution-data (unwrap! (get-contribution contribution-id) ERR-NOT-FOUND))
      (project-data (unwrap! (get-project (get project-id contribution-data)) ERR-NOT-FOUND))
    )
    ;; Only project lead can verify contributions
    (asserts! (is-eq tx-sender (get lead-researcher project-data)) ERR-NOT-AUTHORIZED)
    (asserts! (<= impact-score u100) ERR-INVALID-INPUT)

    ;; Update contribution
    (map-set contributions
      { contribution-id: contribution-id }
      (merge contribution-data { is-verified: true, impact-score: impact-score })
    )

    ;; Update contributor's score
    (let
      (
        (contributor (get contributor contribution-data))
        (project-id (get project-id contribution-data))
      )
      (match (get-project-collaborator project-id contributor)
        collaborator-data
          (map-set project-collaborators
            { project-id: project-id, collaborator: contributor }
            (merge collaborator-data { contribution-score: (+ (get contribution-score collaborator-data) impact-score) })
          )
        false
      )
    )

    (ok true)
  )
)

(define-public (update-project-status (project-id uint) (new-status (string-ascii 32)))
  (let
    (
      (project-data (unwrap! (get-project project-id) ERR-NOT-FOUND))
    )
    ;; Only project lead can update status
    (asserts! (is-eq tx-sender (get lead-researcher project-data)) ERR-NOT-AUTHORIZED)

    (map-set collaboration-projects
      { project-id: project-id }
      (merge project-data { status: new-status })
    )

    (ok true)
  )
)

(define-public (create-researcher-profile
  (name (string-utf8 128))
  (institution (string-utf8 128))
  (research-fields (string-ascii 128))
)
  (let
    (
      (researcher tx-sender)
      (current-time block-height)
    )
    ;; Input validation
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len institution) u0) ERR-INVALID-INPUT)
    (asserts! (> (len research-fields) u0) ERR-INVALID-INPUT)

    ;; Check if profile already exists
    (asserts! (is-none (get-researcher-profile researcher)) ERR-ALREADY-EXISTS)

    ;; Create profile
    (map-set researcher-profiles
      { researcher: researcher }
      {
        name: name,
        institution: institution,
        research-fields: research-fields,
        collaboration-score: u0,
        total-contributions: u0,
        active-projects: u0,
        last-active: current-time
      }
    )

    (ok true)
  )
)

;; Private functions
(define-private (update-researcher-profile-for-project (researcher principal))
  (match (get-researcher-profile researcher)
    existing-profile
      (map-set researcher-profiles
        { researcher: researcher }
        (merge existing-profile {
          active-projects: (+ (get active-projects existing-profile) u1),
          last-active: block-height
        })
      )
    true
  )
)

(define-private (update-researcher-profile-for-contribution (researcher principal))
  (match (get-researcher-profile researcher)
    existing-profile
      (let
        (
          (new-total (+ (get total-contributions existing-profile) u1))
          (new-score (calculate-collaboration-score new-total (get active-projects existing-profile) u0))
        )
        (map-set researcher-profiles
          { researcher: researcher }
          (merge existing-profile {
            total-contributions: new-total,
            collaboration-score: new-score,
            last-active: block-height
          })
        )
      )
    true
  )
)
