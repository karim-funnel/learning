1. In a markdown note or notebook, answer:

   - Which Pagila tables clearly look **transactional** (OLTP) and why?
     A: Payment and rental, because they store daily transactions and change a lot (if they have a lot of customers)

   - Which tables are more **reference / master data**?
     A: Practically all the rest: film, film_category, category, customer, staff, etc. They probably don't change as much as the transactional tables.

   - If you had to build a reporting layer for executives, why might you not query the OLTP schema directly for heavy analytics?
     A: Because I may "lock" the tables used in daily movements. Is better to build a Warehouse (OLAP?) and query that one.

2. Sketch (on paper or in a markdown file) a **star schema** for analyzing rentals and revenue:

   - Identify at least one **fact table** (e.g., `fact_rental` or `fact_payment`).
   - Identify dimensions: `dim_customer`, `dim_film`, `dim_store`, `dim_date`, maybe `dim_staff`, `dim_category`.
   - For each, list key attributes (business keys, natural keys, surrogate keys, measures).

   **A:**

   **Star Schema Design:**

   ```
   fact_rental (center of star)
     ├─ dim_customer (Who rented?)
     ├─ dim_film (What was rented?)
     ├─ dim_staff (Who processed the rental?)
     ├─ dim_store (Which store?)
     └─ dim_date (When was it rented? When returned?)

   fact_payment (separate star for revenue)
     ├─ dim_customer
     ├─ dim_staff
     ├─ dim_store
     ├─ dim_date
     └─ Links to fact_rental via rental_key (fact-to-fact relationship)
   ```

   **Key Terminology (from Week 3 Quick Reference):**

   - **Surrogate Key:** Fake ID you create (e.g., `customer_key = 10001`)
   - **Natural Key:** Real ID from source system (e.g., `customer_id = 42` from Pagila)
   - **Measure:** Numbers you can add/average (e.g., `amount`, `days_rented`)
   - **Attribute:** Descriptive text/categories (e.g., `customer_name`, `rating`)

   **dim_customer:**

   - `customer_key` (surrogate key, PK)
   - `customer_id` (natural key from Pagila)
   - `first_name`, `last_name`, `full_name` (attributes)
   - `email`, `city`, `country` (attributes)
   - `store_id` (which store they belong to)
   - `active_flag` (attribute)

   **dim_film:**

   - `film_key` (surrogate key, PK)
   - `film_id` (natural key)
   - `title`, `description` (attributes)
   - `rating`, `category` (attributes)
   - `length`, `rental_rate` (attributes, though rental_rate might be denormalized into fact)

   **dim_date:**

   - `date_key` (surrogate key, format: 20240115)
   - `full_date`, `day_of_week`, `month`, `quarter`, `year` (attributes)
   - `is_weekend`, `is_holiday` (attributes for analysis)

   **dim_store:**

   - `store_key` (surrogate key)
   - `store_id` (natural key)
   - `address`, `city`, `country` (attributes)
   - `manager_name` (attribute)

   **dim_staff:**

   - `staff_key` (surrogate key)
   - `staff_id` (natural key)
   - `first_name`, `last_name` (attributes)
   - `store_id` (which store they work at)

   **Note on dim_inventory:**

   - Initially included, but inventory is more of a junction between film and store
   - Better to denormalize: fact_rental links directly to film_key and store_key
   - Avoids unnecessary complexity for analysts

## Day 2

1. **Define the grain** of a rental fact table.

   - Write a 2–3 sentence description like: "One row per …".

     **A:** One row per rental event.

   - List what questions this grain enables you to answer.

     **A:** I can see how many rentals per unit of time (hour, day, month, year, total history, etc), most attentive staff member (per unit of time), most rented films (therefore, also categories), most profitable quarters, compare them to the previous one, moving average of rentals per day, behavior on weekends, and a big etc.

   - Decide which measures (columns) belong in `fact_rental` vs should live in dimensions.

     **A:**

     **Structure of `fact_rental`:**

     Foreign Keys:

     - `rental_key` (surrogate key, PK)
     - `rental_id` (natural key from source)
     - `customer_key` (FK to dim_customer)
     - `film_key` (FK to dim_film)
     - `staff_key` (FK to dim_staff)
     - `store_key` (FK to dim_store)
     - `rental_date_key` (FK to dim_date)
     - `return_date_key` (FK to dim_date, can be NULL or "Unknown")

     Measures:

     - `rental_count` (always 1, used for COUNT aggregation)
     - `rental_rate` (price at time of rental, denormalized from dim_film)
     - `days_rented` (DATEDIFF(return_date, rental_date), NULL if not returned)
     - `is_returned` (boolean flag: true/false)
     - `days_late` (calculated: days_rented - expected_duration, 0 if on-time)

     **Why separate `fact_rental` from `fact_payment`?**

     - Different grain: one rental can have multiple payments
     - `fact_rental` answers: "How many rentals?"
     - `fact_payment` answers: "How much revenue?"
     - They can be joined via `rental_key` for combined analysis

     **Key insight:** When grain is transactional, the row itself IS a measure (COUNT(\*) = total rentals)

     **Price evolution tracking:**
     To track historical rental rates, use SCD Type 2 in `dim_film`:

     - When rental_rate changes, create a new row in dim_film with new surrogate key
     - fact_rental links to the correct film_key based on when the rental occurred
     - This preserves historical accuracy: "This rental was $2.99 in 2022, but the same film costs $4.99 today"
     - This is Week 3 Day 3 content (SCD Type 2)!

2. **Design `fact_payment`**

   - Columns to include (at minimum): surrogate key, customer key, store key, staff key, date key, amount, payment method, rental key (if applicable).
     **A:**

   - Think about: should discounts be in the fact? currency? taxes?
     **A:** Maybe as a foreign key. Discounts should be their own table, because I could keep track of coupons or codes with expiration dates. Currency could be in the fact, why not; one payment is associated to one currency. We could use a conversion rate history table. Taxes is a tricky one. Maybe also as a different dim table? Taxes could change over time also.

3. **Bonus SQL** – Write `CREATE TABLE` statements for `fact_payment` and `dim_customer` as you've designed them (even if you don't populate them yet).
