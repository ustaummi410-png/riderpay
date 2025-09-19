;; Rider Management Contract
;; Manages rider registration, verification, performance tracking, and payment distribution
;; Maintains rider profiles, ratings, and availability status for delivery services

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u2001))
(define-constant ERR_RIDER_NOT_FOUND (err u2002))
(define-constant ERR_RIDER_ALREADY_EXISTS (err u2003))
(define-constant ERR_RIDER_NOT_ACTIVE (err u2004))
(define-constant ERR_INVALID_RATING (err u2005))
(define-constant ERR_INSUFFICIENT_BALANCE (err u2006))
(define-constant ERR_PAYMENT_FAILED (err u2007))
(define-constant ERR_INVALID_STATUS (err u2008))
(define-constant ERR_VERIFICATION_REQUIRED (err u2009))
(define-constant ERR_INVALID_COMMISSION_RATE (err u2010))

;; Rider Status Constants
(define-constant RIDER_PENDING u1)
(define-constant RIDER_VERIFIED u2)
(define-constant RIDER_ACTIVE u3)
(define-constant RIDER_INACTIVE u4)
(define-constant RIDER_SUSPENDED u5)
(define-constant RIDER_BANNED u6)

;; Rating Constants
(define-constant MIN_RATING u1)
(define-constant MAX_RATING u5)
(define-constant DEFAULT_RATING u5)

;; Commission and Performance Settings
(define-constant DEFAULT_COMMISSION_RATE u10) ;; 10%
(define-constant MIN_RATING_FOR_BONUS u4) ;; 4+ stars for bonus eligibility
(define-constant PERFORMANCE_REVIEW_THRESHOLD u20) ;; Reviews after 20 deliveries

;; Data Variables
(define-data-var total-riders uint u0)
(define-data-var total-verified-riders uint u0)
(define-data-var platform-commission-rate uint DEFAULT_COMMISSION_RATE)
(define-data-var total-payments-distributed uint u0)

;; Rider Profile Data Structure
(define-map riders
  { rider: principal }
  {
    name: (string-ascii 100),
    phone: (string-ascii 20),
    email: (string-ascii 100),
    vehicle-type: (string-ascii 50),
    license-number: (string-ascii 50),
    status: uint,
    registration-date: uint,
    last-active: uint,
    verification-date: (optional uint),
    suspension-reason: (optional (string-ascii 500)),
    total-earnings: uint,
    available-balance: uint
  })

;; Rider Performance Metrics
(define-map rider-performance
  { rider: principal }
  {
    total-deliveries: uint,
    completed-deliveries: uint,
    cancelled-deliveries: uint,
    disputed-deliveries: uint,
    average-rating: uint, ;; Multiplied by 100 for precision (e.g., 450 = 4.50 stars)
    total-rating-points: uint,
    total-ratings-received: uint,
    on-time-deliveries: uint,
    late-deliveries: uint,
    response-time-avg: uint ;; Average time to accept orders in minutes
  })

;; Rider Availability Status
(define-map rider-availability
  { rider: principal }
  {
    is-available: bool,
    current-capacity: uint,
    max-capacity: uint,
    working-hours-start: uint, ;; Hour of day (0-23)
    working-hours-end: uint,   ;; Hour of day (0-23)
    preferred-zones: (list 10 (string-ascii 50)),
    last-location-update: uint
  })

;; Rider Ratings and Reviews
(define-map rider-ratings
  { rider: principal, rating-index: uint }
  {
    customer: principal,
    order-id: uint,
    rating: uint, ;; 1-5 stars
    review: (optional (string-ascii 500)),
    created-at: uint
  })

;; Rider Rating Counts
(define-map rider-rating-counts
  principal
  uint)

;; Payment History
(define-map payment-history
  { rider: principal, payment-index: uint }
  {
    order-id: uint,
    base-payment: uint,
    bonus-payment: uint,
    commission-deducted: uint,
    net-payment: uint,
    payment-date: uint,
    payment-type: (string-ascii 20) ;; "delivery", "bonus", "adjustment"
  })

;; Rider Payment Counts
(define-map rider-payment-counts
  principal
  uint)

;; Verification Records
(define-map verification-records
  { rider: principal }
  {
    verified-by: principal,
    verification-date: uint,
    documents-verified: (list 10 (string-ascii 100)),
    verification-notes: (optional (string-ascii 500))
  })

;; Commission Tiers (based on performance)
(define-map commission-tiers
  { tier: uint }
  {
    min-deliveries: uint,
    min-rating: uint, ;; Multiplied by 100
    commission-rate: uint,
    bonus-eligible: bool
  })

;; Private Functions

;; Check if rider is authorized to perform action
(define-private (is-rider-authorized (rider principal))
  (match (map-get? riders { rider: rider })
    rider-data (let
                 ((status (get status rider-data)))
                 (or (is-eq status RIDER_VERIFIED)
                     (is-eq status RIDER_ACTIVE)))
    false))

;; Calculate rider's current commission tier
(define-private (calculate-commission-tier (rider principal))
  (match (map-get? rider-performance { rider: rider })
    perf-data (let
                ((deliveries (get total-deliveries perf-data))
                 (rating (get average-rating perf-data)))
                (if (and (>= deliveries u50) (>= rating u450))
                  u3 ;; Premium tier
                  (if (and (>= deliveries u20) (>= rating u400))
                    u2 ;; Gold tier
                    u1))) ;; Standard tier
    u1)) ;; Default to standard

;; Calculate net payment after commission
(define-private (calculate-net-payment (rider principal) (gross-amount uint))
  (let
    ((tier (calculate-commission-tier rider))
     (commission-rate (default-to DEFAULT_COMMISSION_RATE 
                       (get commission-rate (map-get? commission-tiers { tier: tier }))))
     (commission-amount (/ (* gross-amount commission-rate) u100)))
    (- gross-amount commission-amount)))

;; Update rider performance metrics
(define-private (update-rider-performance (rider principal) (delivery-completed bool) (rating (optional uint)))
  (begin
    (match (map-get? rider-performance { rider: rider })
      perf-data (let
                  ((new-total (+ (get total-deliveries perf-data) u1))
                   (new-completed (if delivery-completed 
                                   (+ (get completed-deliveries perf-data) u1)
                                   (get completed-deliveries perf-data)))
                   (rating-update (match rating
                                  some-rating (let
                                               ((new-points (+ (get total-rating-points perf-data) some-rating))
                                                (new-count (+ (get total-ratings-received perf-data) u1)))
                                               { total-rating-points: new-points,
                                                 total-ratings-received: new-count,
                                                 average-rating: (/ (* new-points u100) new-count) })
                                  { total-rating-points: (get total-rating-points perf-data),
                                    total-ratings-received: (get total-ratings-received perf-data),
                                    average-rating: (get average-rating perf-data) })))
                  (map-set rider-performance
                    { rider: rider }
                    (merge perf-data
                      (merge rating-update
                        {
                          total-deliveries: new-total,
                          completed-deliveries: new-completed
                        }))))
      ;; Initialize performance if not exists
      (map-set rider-performance
        { rider: rider }
        {
          total-deliveries: u1,
          completed-deliveries: (if delivery-completed u1 u0),
          cancelled-deliveries: u0,
          disputed-deliveries: u0,
          average-rating: (* DEFAULT_RATING u100),
          total-rating-points: (match rating some-val some-val (* DEFAULT_RATING u100)),
          total-ratings-received: (if (is-some rating) u1 u0),
          on-time-deliveries: u0,
          late-deliveries: u0,
          response-time-avg: u0
        }))
    true))
;; Read-Only Functions

;; Get rider profile
(define-read-only (get-rider (rider principal))
  (map-get? riders { rider: rider }))

;; Get rider performance metrics
(define-read-only (get-rider-performance (rider principal))
  (map-get? rider-performance { rider: rider }))

;; Get rider availability
(define-read-only (get-rider-availability (rider principal))
  (map-get? rider-availability { rider: rider }))

;; Get rider rating by index
(define-read-only (get-rider-rating (rider principal) (rating-index uint))
  (map-get? rider-ratings { rider: rider, rating-index: rating-index }))

;; Get rider's total rating count
(define-read-only (get-rider-rating-count (rider principal))
  (default-to u0 (map-get? rider-rating-counts rider)))

;; Get payment history by index
(define-read-only (get-payment-history (rider principal) (payment-index uint))
  (map-get? payment-history { rider: rider, payment-index: payment-index }))

;; Get rider's payment count
(define-read-only (get-rider-payment-count (rider principal))
  (default-to u0 (map-get? rider-payment-counts rider)))

;; Get verification record
(define-read-only (get-verification-record (rider principal))
  (map-get? verification-records { rider: rider }))

;; Get commission tier details
(define-read-only (get-commission-tier (tier uint))
  (map-get? commission-tiers { tier: tier }))

;; Get platform statistics
(define-read-only (get-platform-rider-stats)
  {
    total-riders: (var-get total-riders),
    verified-riders: (var-get total-verified-riders),
    commission-rate: (var-get platform-commission-rate),
    total-payments: (var-get total-payments-distributed)
  })

;; Check if rider is active and available
(define-read-only (is-rider-available (rider principal))
  (match (map-get? rider-availability { rider: rider })
    availability-data (and
                       (get is-available availability-data)
                       (< (get current-capacity availability-data) (get max-capacity availability-data))
                       (is-rider-authorized rider))
    false))

;; Public Functions

;; Register as a new rider
(define-public (register-rider (name (string-ascii 100))
                              (phone (string-ascii 20))
                              (email (string-ascii 100))
                              (vehicle-type (string-ascii 50))
                              (license-number (string-ascii 50)))
  (let
    ((current-time u1))
    (begin
      ;; Check if rider doesn't already exist
      (asserts! (is-none (map-get? riders { rider: tx-sender })) ERR_RIDER_ALREADY_EXISTS)
      
      ;; Create rider profile
      (map-set riders
        { rider: tx-sender }
        {
          name: name,
          phone: phone,
          email: email,
          vehicle-type: vehicle-type,
          license-number: license-number,
          status: RIDER_PENDING,
          registration-date: current-time,
          last-active: current-time,
          verification-date: none,
          suspension-reason: none,
          total-earnings: u0,
          available-balance: u0
        })
      
      ;; Initialize availability (inactive by default)
      (map-set rider-availability
        { rider: tx-sender }
        {
          is-available: false,
          current-capacity: u0,
          max-capacity: u3, ;; Default max 3 concurrent deliveries
          working-hours-start: u9, ;; 9 AM
          working-hours-end: u21,  ;; 9 PM
          preferred-zones: (list),
          last-location-update: current-time
        })
      
      ;; Update total riders count
      (var-set total-riders (+ (var-get total-riders) u1))
      
      (print { action: "rider-registered", rider: tx-sender, name: name })
      (ok true))))

;; Update rider availability status
(define-public (set-availability (is-available bool) (max-capacity uint))
  (let
    ((current-time u1))
    (begin
      ;; Check rider exists and is authorized
      (asserts! (is-rider-authorized tx-sender) ERR_RIDER_NOT_ACTIVE)
      
      ;; Update availability
      (match (map-get? rider-availability { rider: tx-sender })
        availability-data (map-set rider-availability
                           { rider: tx-sender }
                           (merge availability-data
                             {
                               is-available: is-available,
                               max-capacity: max-capacity,
                               last-location-update: current-time
                             }))
        ;; Should not happen if rider is authorized, but handle gracefully
        false)
      
      ;; Update last active time
      (match (map-get? riders { rider: tx-sender })
        rider-data (map-set riders
                     { rider: tx-sender }
                     (merge rider-data { last-active: current-time }))
        false)
      
      (print { action: "availability-updated", rider: tx-sender, available: is-available })
      (ok true))))

;; Add rating for rider
(define-public (add-rider-rating (rider principal) (order-id uint) (rating uint) (review (optional (string-ascii 500))))
  (let
    ((current-time u1)
     (rating-count (get-rider-rating-count rider))
     (rating-index rating-count))
    (begin
      ;; Validate rating range
      (asserts! (and (>= rating MIN_RATING) (<= rating MAX_RATING)) ERR_INVALID_RATING)
      ;; Check rider exists
      (asserts! (is-some (map-get? riders { rider: rider })) ERR_RIDER_NOT_FOUND)
      
      ;; Add rating record
      (map-set rider-ratings
        { rider: rider, rating-index: rating-index }
        {
          customer: tx-sender,
          order-id: order-id,
          rating: rating,
          review: review,
          created-at: current-time
        })
      
      ;; Update rating count
      (map-set rider-rating-counts rider (+ rating-count u1))
      
      ;; Update performance metrics with new rating
      (update-rider-performance rider true (some rating))
      
      (print { action: "rating-added", rider: rider, rating: rating, order-id: order-id })
      (ok true))))

;; Process payment to rider
(define-public (process-rider-payment (rider principal) 
                                    (order-id uint)
                                    (base-payment uint)
                                    (bonus-payment uint))
  (let
    ((current-time u1)
     (gross-payment (+ base-payment bonus-payment))
     (commission-amount (/ (* gross-payment (var-get platform-commission-rate)) u100))
     (net-payment (- gross-payment commission-amount))
     (payment-count (get-rider-payment-count rider))
     (payment-index payment-count))
    (begin
      ;; Check rider exists and is authorized
      (asserts! (is-rider-authorized rider) ERR_RIDER_NOT_ACTIVE)
      
      ;; Add payment record
      (map-set payment-history
        { rider: rider, payment-index: payment-index }
        {
          order-id: order-id,
          base-payment: base-payment,
          bonus-payment: bonus-payment,
          commission-deducted: commission-amount,
          net-payment: net-payment,
          payment-date: current-time,
          payment-type: "delivery"
        })
      
      ;; Update payment count
      (map-set rider-payment-counts rider (+ payment-count u1))
      
      ;; Update rider earnings and balance
      (match (map-get? riders { rider: rider })
        rider-data (map-set riders
                     { rider: rider }
                     (merge rider-data
                       {
                         total-earnings: (+ (get total-earnings rider-data) net-payment),
                         available-balance: (+ (get available-balance rider-data) net-payment)
                       }))
        false)
      
      ;; Update platform statistics
      (var-set total-payments-distributed (+ (var-get total-payments-distributed) net-payment))
      
      (print { action: "payment-processed", rider: rider, net-payment: net-payment, order-id: order-id })
      (ok net-payment))))

;; Administrative Functions

;; Verify rider (only contract owner or authorized verifiers)
(define-public (verify-rider (rider principal) (documents (list 10 (string-ascii 100))) (notes (optional (string-ascii 500))))
  (let
    ((current-time u1))
    (begin
      ;; Only contract owner can verify
      (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
      ;; Check rider exists
      (asserts! (is-some (map-get? riders { rider: rider })) ERR_RIDER_NOT_FOUND)
      
      ;; Create verification record
      (map-set verification-records
        { rider: rider }
        {
          verified-by: tx-sender,
          verification-date: current-time,
          documents-verified: documents,
          verification-notes: notes
        })
      
      ;; Update rider status
      (match (map-get? riders { rider: rider })
        rider-data (map-set riders
                     { rider: rider }
                     (merge rider-data
                       {
                         status: RIDER_VERIFIED,
                         verification-date: (some current-time)
                       }))
        false)
      
      ;; Update verified riders count
      (var-set total-verified-riders (+ (var-get total-verified-riders) u1))
      
      (print { action: "rider-verified", rider: rider, verified-by: tx-sender })
      (ok true))))

;; Set platform commission rate (only owner)
(define-public (set-commission-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-rate u50) ERR_INVALID_COMMISSION_RATE) ;; Max 50%
    (var-set platform-commission-rate new-rate)
    (print { action: "commission-rate-updated", new-rate: new-rate })
    (ok true)))

;; Initialize commission tiers
(map-set commission-tiers { tier: u1 } { min-deliveries: u0, min-rating: u300, commission-rate: u15, bonus-eligible: false })
(map-set commission-tiers { tier: u2 } { min-deliveries: u20, min-rating: u400, commission-rate: u10, bonus-eligible: true })
(map-set commission-tiers { tier: u3 } { min-deliveries: u50, min-rating: u450, commission-rate: u5, bonus-eligible: true })

;; Initialize contract
(print { action: "rider-management-initialized", owner: CONTRACT_OWNER })

