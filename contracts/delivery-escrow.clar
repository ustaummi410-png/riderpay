;; Delivery Escrow Contract
;; Manages secure escrow payments for motorbike delivery orders
;; Handles order creation, payment deposits, and automatic fund releases

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1001))
(define-constant ERR_ORDER_NOT_FOUND (err u1002))
(define-constant ERR_INVALID_ORDER_STATUS (err u1003))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u1004))
(define-constant ERR_ORDER_ALREADY_EXISTS (err u1005))
(define-constant ERR_INVALID_PARTICIPANT (err u1006))
(define-constant ERR_PAYMENT_TRANSFER_FAILED (err u1007))
(define-constant ERR_REFUND_FAILED (err u1008))
(define-constant ERR_DISPUTE_ACTIVE (err u1009))
(define-constant ERR_DELIVERY_TIMEOUT (err u1010))

;; Order Status Constants
(define-constant ORDER_CREATED u1)
(define-constant ORDER_ACCEPTED u2)
(define-constant ORDER_PICKED_UP u3)
(define-constant ORDER_IN_TRANSIT u4)
(define-constant ORDER_DELIVERED u5)
(define-constant ORDER_COMPLETED u6)
(define-constant ORDER_CANCELLED u7)
(define-constant ORDER_DISPUTED u8)

;; Platform Settings
(define-constant PLATFORM_COMMISSION_RATE u5) ;; 5%
(define-constant MAX_DELIVERY_TIME_BLOCKS u1440) ;; ~24 hours in blocks
(define-constant DISPUTE_RESOLUTION_TIME u720) ;; ~12 hours in blocks

;; Data Variables
(define-data-var next-order-id uint u1)
(define-data-var platform-wallet principal tx-sender)
(define-data-var total-orders uint u0)
(define-data-var total-volume uint u0)

;; Order Data Structure
(define-map orders
  { order-id: uint }
  {
    customer: principal,
    rider: (optional principal),
    pickup-address: (string-ascii 200),
    delivery-address: (string-ascii 200),
    item-description: (string-ascii 500),
    payment-amount: uint,
    commission-amount: uint,
    rider-payment: uint,
    status: uint,
    created-at: uint,
    accepted-at: (optional uint),
    picked-up-at: (optional uint),
    delivered-at: (optional uint),
    completed-at: (optional uint),
    dispute-reason: (optional (string-ascii 500)),
    dispute-created-at: (optional uint)
  })

;; Order Ratings
(define-map order-ratings
  { order-id: uint }
  {
    customer-rating: (optional uint), ;; 1-5 stars
    rider-rating: (optional uint), ;; 1-5 stars
    customer-feedback: (optional (string-ascii 500)),
    rider-feedback: (optional (string-ascii 500))
  })

;; Escrow Balances
(define-map escrow-balances
  { order-id: uint }
  uint)

;; Customer Order History
(define-map customer-orders
  { customer: principal, order-index: uint }
  uint)

;; Customer Order Counts
(define-map customer-order-counts
  principal
  uint)

;; Rider Order History
(define-map rider-orders
  { rider: principal, order-index: uint }
  uint)

;; Rider Order Counts
(define-map rider-order-counts
  principal
  uint)

;; Dispute Records
(define-map dispute-records
  { order-id: uint }
  {
    initiated-by: principal,
    reason: (string-ascii 500),
    resolution: (optional (string-ascii 500)),
    resolved-by: (optional principal),
    resolved-at: (optional uint)
  })

;; Private Functions

;; Calculate commission amount
(define-private (calculate-commission (payment-amount uint))
  (/ (* payment-amount PLATFORM_COMMISSION_RATE) u100))

;; Calculate rider payment after commission
(define-private (calculate-rider-payment (payment-amount uint))
  (- payment-amount (calculate-commission payment-amount)))

;; Check if user is authorized (customer, rider, or owner)
(define-private (is-authorized-user (order-id uint) (user principal))
  (match (map-get? orders { order-id: order-id })
    order-data (or 
                 (is-eq user (get customer order-data))
                 (is-eq user (default-to 'SP000000000000000000002Q6VF78 (get rider order-data)))
                 (is-eq user CONTRACT_OWNER))
    false))

;; Check if order has timed out
(define-private (is-order-timed-out (order-id uint))
  (match (map-get? orders { order-id: order-id })
    order-data (let
                 ((current-time u1)
                  (created-time (get created-at order-data)))
                 (> (- current-time created-time) MAX_DELIVERY_TIME_BLOCKS))
    false))

;; Add order to customer history
(define-private (add-to-customer-history (customer principal) (order-id uint))
  (let
    ((current-count (default-to u0 (map-get? customer-order-counts customer))))
    (begin
      (map-set customer-orders { customer: customer, order-index: current-count } order-id)
      (map-set customer-order-counts customer (+ current-count u1)))))

;; Add order to rider history
(define-private (add-to-rider-history (rider principal) (order-id uint))
  (let
    ((current-count (default-to u0 (map-get? rider-order-counts rider))))
    (begin
      (map-set rider-orders { rider: rider, order-index: current-count } order-id)
      (map-set rider-order-counts rider (+ current-count u1)))))

;; Read-Only Functions

;; Get order details
(define-read-only (get-order (order-id uint))
  (map-get? orders { order-id: order-id }))

;; Get order ratings
(define-read-only (get-order-ratings (order-id uint))
  (map-get? order-ratings { order-id: order-id }))

;; Get escrow balance for order
(define-read-only (get-escrow-balance (order-id uint))
  (default-to u0 (map-get? escrow-balances { order-id: order-id })))

;; Get customer order count
(define-read-only (get-customer-order-count (customer principal))
  (default-to u0 (map-get? customer-order-counts customer)))

;; Get rider order count
(define-read-only (get-rider-order-count (rider principal))
  (default-to u0 (map-get? rider-order-counts rider)))

;; Get customer order by index
(define-read-only (get-customer-order-by-index (customer principal) (index uint))
  (map-get? customer-orders { customer: customer, order-index: index }))

;; Get rider order by index
(define-read-only (get-rider-order-by-index (rider principal) (index uint))
  (map-get? rider-orders { rider: rider, order-index: index }))

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-orders: (var-get total-orders),
    total-volume: (var-get total-volume),
    next-order-id: (var-get next-order-id),
    platform-wallet: (var-get platform-wallet)
  })

;; Get dispute record
(define-read-only (get-dispute-record (order-id uint))
  (map-get? dispute-records { order-id: order-id }))

;; Check if order can be cancelled
(define-read-only (can-cancel-order (order-id uint))
  (match (map-get? orders { order-id: order-id })
    order-data (let
                 ((status (get status order-data)))
                 (or (is-eq status ORDER_CREATED) (is-eq status ORDER_ACCEPTED)))
    false))

;; Public Functions

;; Create new delivery order
(define-public (create-order (pickup-address (string-ascii 200)) 
                           (delivery-address (string-ascii 200))
                           (item-description (string-ascii 500))
                           (payment-amount uint))
  (let
    ((order-id (var-get next-order-id))
     (commission (calculate-commission payment-amount))
     (rider-payment (calculate-rider-payment payment-amount))
     (current-time u1))
    (begin
      ;; Validate payment amount
      (asserts! (> payment-amount u0) ERR_INSUFFICIENT_PAYMENT)
      
      ;; Transfer payment to contract escrow
      (try! (stx-transfer? payment-amount tx-sender (as-contract tx-sender)))
      
      ;; Create order record
      (map-set orders
        { order-id: order-id }
        {
          customer: tx-sender,
          rider: none,
          pickup-address: pickup-address,
          delivery-address: delivery-address,
          item-description: item-description,
          payment-amount: payment-amount,
          commission-amount: commission,
          rider-payment: rider-payment,
          status: ORDER_CREATED,
          created-at: current-time,
          accepted-at: none,
          picked-up-at: none,
          delivered-at: none,
          completed-at: none,
          dispute-reason: none,
          dispute-created-at: none
        })
      
      ;; Set escrow balance
      (map-set escrow-balances { order-id: order-id } payment-amount)
      
      ;; Add to customer history
      (add-to-customer-history tx-sender order-id)
      
      ;; Update platform statistics
      (var-set next-order-id (+ order-id u1))
      (var-set total-orders (+ (var-get total-orders) u1))
      (var-set total-volume (+ (var-get total-volume) payment-amount))
      
      (print { action: "order-created", order-id: order-id, customer: tx-sender, amount: payment-amount })
      (ok order-id))))

;; Rider accepts delivery order
(define-public (accept-order (order-id uint))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (current-time u1))
    (begin
      ;; Validate order status
      (asserts! (is-eq (get status order-data) ORDER_CREATED) ERR_INVALID_ORDER_STATUS)
      
      ;; Update order with rider assignment
      (map-set orders
        { order-id: order-id }
        (merge order-data
          {
            rider: (some tx-sender),
            status: ORDER_ACCEPTED,
            accepted-at: (some current-time)
          }))
      
      ;; Add to rider history
      (add-to-rider-history tx-sender order-id)
      
      (print { action: "order-accepted", order-id: order-id, rider: tx-sender })
      (ok true))))

;; Rider confirms item pickup
(define-public (confirm-pickup (order-id uint))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (current-time u1))
    (begin
      ;; Validate rider
      (asserts! (is-eq (some tx-sender) (get rider order-data)) ERR_NOT_AUTHORIZED)
      ;; Validate order status
      (asserts! (is-eq (get status order-data) ORDER_ACCEPTED) ERR_INVALID_ORDER_STATUS)
      
      ;; Update order status
      (map-set orders
        { order-id: order-id }
        (merge order-data
          {
            status: ORDER_PICKED_UP,
            picked-up-at: (some current-time)
          }))
      
      (print { action: "pickup-confirmed", order-id: order-id, rider: tx-sender })
      (ok true))))

;; Rider/Customer confirms delivery completion
(define-public (confirm-delivery (order-id uint))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (current-time u1))
    (begin
      ;; Validate authorized user (customer or rider)
      (asserts! (is-authorized-user order-id tx-sender) ERR_NOT_AUTHORIZED)
      ;; Validate order status
      (asserts! (or (is-eq (get status order-data) ORDER_PICKED_UP) 
                    (is-eq (get status order-data) ORDER_IN_TRANSIT)) ERR_INVALID_ORDER_STATUS)
      
      ;; Update order status
      (map-set orders
        { order-id: order-id }
        (merge order-data
          {
            status: ORDER_DELIVERED,
            delivered-at: (some current-time)
          }))
      
      ;; Process payment release
      (try! (release-payment order-id))
      
      (print { action: "delivery-confirmed", order-id: order-id, confirmed-by: tx-sender })
      (ok true))))

;; Release escrowed payment to rider and platform
(define-public (release-payment (order-id uint))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (escrow-amount (get-escrow-balance order-id))
     (rider-payment (get rider-payment order-data))
     (commission (get commission-amount order-data))
     (rider (unwrap! (get rider order-data) ERR_INVALID_PARTICIPANT))
     (current-time u1))
    (begin
      ;; Validate order status
      (asserts! (is-eq (get status order-data) ORDER_DELIVERED) ERR_INVALID_ORDER_STATUS)
      ;; Validate sufficient escrow balance
      (asserts! (>= escrow-amount (+ rider-payment commission)) ERR_INSUFFICIENT_PAYMENT)
      
      ;; Transfer payment to rider
      (try! (as-contract (stx-transfer? rider-payment tx-sender rider)))
      
      ;; Transfer commission to platform
      (try! (as-contract (stx-transfer? commission tx-sender (var-get platform-wallet))))
      
      ;; Update order status
      (map-set orders
        { order-id: order-id }
        (merge order-data
          {
            status: ORDER_COMPLETED,
            completed-at: (some current-time)
          }))
      
      ;; Clear escrow balance
      (map-delete escrow-balances { order-id: order-id })
      
      (print { action: "payment-released", order-id: order-id, rider-payment: rider-payment, commission: commission })
      (ok true))))

;; Cancel order (only if not yet accepted)
(define-public (cancel-order (order-id uint))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (escrow-amount (get-escrow-balance order-id)))
    (begin
      ;; Validate customer authorization
      (asserts! (is-eq tx-sender (get customer order-data)) ERR_NOT_AUTHORIZED)
      ;; Validate order can be cancelled
      (asserts! (can-cancel-order order-id) ERR_INVALID_ORDER_STATUS)
      
      ;; Refund payment to customer
      (try! (as-contract (stx-transfer? escrow-amount tx-sender (get customer order-data))))
      
      ;; Update order status
      (map-set orders
        { order-id: order-id }
        (merge order-data { status: ORDER_CANCELLED }))
      
      ;; Clear escrow balance
      (map-delete escrow-balances { order-id: order-id })
      
      (print { action: "order-cancelled", order-id: order-id, refund-amount: escrow-amount })
      (ok true))))

;; Create dispute
(define-public (create-dispute (order-id uint) (reason (string-ascii 500)))
  (let
    ((order-data (unwrap! (map-get? orders { order-id: order-id }) ERR_ORDER_NOT_FOUND))
     (current-time u1))
    (begin
      ;; Validate authorized user
      (asserts! (is-authorized-user order-id tx-sender) ERR_NOT_AUTHORIZED)
      ;; Validate order is not already completed or cancelled
      (asserts! (not (or (is-eq (get status order-data) ORDER_COMPLETED)
                        (is-eq (get status order-data) ORDER_CANCELLED))) ERR_INVALID_ORDER_STATUS)
      
      ;; Create dispute record
      (map-set dispute-records
        { order-id: order-id }
        {
          initiated-by: tx-sender,
          reason: reason,
          resolution: none,
          resolved-by: none,
          resolved-at: none
        })
      
      ;; Update order status
      (map-set orders
        { order-id: order-id }
        (merge order-data
          {
            status: ORDER_DISPUTED,
            dispute-reason: (some reason),
            dispute-created-at: (some current-time)
          }))
      
      (print { action: "dispute-created", order-id: order-id, initiated-by: tx-sender, reason: reason })
      (ok true))))

;; Administrative Functions

;; Set platform wallet (only owner)
(define-public (set-platform-wallet (new-wallet principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set platform-wallet new-wallet)
    (print { action: "platform-wallet-updated", new-wallet: new-wallet })
    (ok true)))

;; Initialize contract
(print { action: "contract-initialized", owner: CONTRACT_OWNER })

