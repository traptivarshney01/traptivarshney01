use orders_new;

/* Problem Statement:
There is a Brazilian ecommerce public dataset of orders made at Olist Store. The dataset has information of multiple marketplaces in Brazil. 
Its features allow viewing an order from multiple dimensions: order status, price, payment and freight performance to customer location, product attributes 
and finally reviews written by customers, it is a geolocation dataset that relates Brazilian zip codes to latitudes /longitudes coordinates. */ 

/* 1) Write a SQL query to display all order statuses with their customer ids and rank each status based upon the descending order of counts in a new column as
“Rank_Order_Status” for all the order statuses which are anything but delivered.
Find out the top3 ranked statuses from the new column created. Comment if the orders shipped are more than the orders unavailable/lost during shipping */  

-- ANSWER 1 

select order_status , count(*) , rank() over (order by count(*) desc) as rank_order_status
from order1 where order_status !='delivered'  group by order_status order by count(*) desc limit 3;
-- False is the answer 

/* 2) Write a SQL query to display all product names with their respective price and the
cumulative percentile for price which is greater than 0.5 */

-- ANSWER 2
select * from 
(Select PRODUCT_NAME_LENGHT, price , cume_dist() over (order by price) cum_dist 
from product p join items i using(product_id)  group by PRODUCT_NAME_LENGHT) t
where cum_dist > 0.5; 

/* 3) Write a SQL query to display average weight of products, average freight value for the products whose 2nd letter of the name is ‘e’ and 
the last letter is ‘a’ and for those products the seller is shipping the same from ‘sao paulo’ */

-- ANSWER 3 
select PRODUCT_NAME_LENGHT, avg(PRODUCT_WEIGHT_G), avg(FREIGHT_VALUE), SELLER_CITY
from product p join items i using(PRODUCT_ID) join seller s using(seller_id) where product_name_lenght like '_e%a' and  seller_city = 'sao paulo' 
group by PRODUCT_NAME_LENGHT;

/* 4) Write a SQL query to display product length, product name, “Modified ProductName” which is defined as:
If product length < 500 then modify the product name to all Uppercase
If 500<=product length<1500 then reverse the product name
If 1500<=product length<2500 then add “000” at the end of each product name
If 2500<=product length<3500 then replace all ‘a’ with ‘A’ in each of the product name
If 3500<=product length<5000 then duplicate the product name 2 times without any space
If product length >= 5000 then modify the product name to extract
 last 4 characters from the product name (*USE Case statement*) */
 
 --  ANSWER 4

select PRODUCT_NAME_LENGHT, PRODUCT_LENGTH_CM,
	case 
		when PRODUCT_LENGTH_CM <500 then upper(PRODUCT_NAME_LENGHT) 
		when PRODUCT_LENGTH_CM >=500 and PRODUCT_LENGTH_CM <1500 then reverse(PRODUCT_NAME_LENGHT)
		when PRODUCT_LENGTH_CM>=1500 and PRODUCT_LENGTH_CM<2500 then concat(PRODUCT_NAME_LENGHT, '000')
		when PRODUCT_LENGTH_CM>=2500 and PRODUCT_LENGTH_CM<3500 then replace (PRODUCT_NAME_LENGHT, 'a', 'A')
		when PRODUCT_LENGTH_CM>=3500 and PRODUCT_LENGTH_CM <5000 then repeat(PRODUCT_NAME_LENGHT,2)  #repeat - no spacing 
		when PRODUCT_LENGTH_CM>=5000 then right(PRODUCT_NAME_LENGHT,4)  #or we can use - substr(PRODUCT_NAME_LENGHT,-4)
		else 'others'  # else is optional 
	end modified_product_name
from product; 

/* 5)  Write a SQL query to display all the customers, products, and their review scores
which are greater than the minimum review score*/ 
-- Answer 5---------------
select min(REVIEW_SCORE) from order_review;

select CUSTOMER_ID , PRODUCT_NAME_LENGHT , REVIEW_SCORE  from customer c join order1 o using (customer_id) 
join order_review orr using(order_id)  join items i using(order_id)
join product p using(product_id)
where review_score> (select min(review_score) from order_review);

/* 6) Write a SQL query to display how many days does it take for the customer to get the ordered products whose seller resides in the same city, 
also display the seller and the customer city with the product and customer details */ 

-- ANSWER 6 -----------
select customer_id, product_NAME_LENGHT,order_status,
datediff(ORDER_DELIVERED_CUSTOMER_DATE, ORDER_PURCHASE_TIMESTAMP) delivery_days , seller_city, customer_city
from customer c join order1 o using (CUSTOMER_ID) join items i using (ORDER_ID) join product p using (product_id) 
join seller s using(seller_id) where customer_city= seller_city;      
 -- # Null in output means one of the two value(_time stamp)  in date diff is not present means order delivered but not yet delivered 
 -- # see order status shows in 'processing'
 
 
 /* 7) Write a SQL query to display all the products names with their total prices for
which the total price for each product is greater than the total price for product
'eletronicos'*/ 

select PRODUCT_NAME_LENGHT, sum(price)  from product p join items i using( product_id) 
 group by PRODUCT_NAME_LENGHT having sum(price) 
>(select sum(price)  from product p join items i using( product_id) 
where PRODUCT_NAME_LENGHT='eletronicos') ;

/* 8) Write a SQL query to display all the customer id’s and order statuses also compute the delivery days that an item took to get delivered in a separate column as
“reached_in_days” and if the computed values are null the replace with ‘NA’ and also create a new column as “delivery_comments” which should have the
comments for the similar comparisons (a) if the item got delivered within 7 days put the same as comment (b) if the item got delivered between 7 to 30 days put
the comment as "Order delivered with Delay of few days " (c) if the item got delivered after 30 days put the comment as "Order delivered with Delay of a
month " (d) "Order not delivered yet" */

with delivery_details as (   --  ## we are storing the info in a table name de;ivery_details 
select order_id, datediff(order_delivered_customer_date, order_purchase_timestamp) delivery_days from order1) 
select * , case
				when delivery_days<7 then ' Item got delivered withinin 7 days '
                when delivery_days between 7 and 30 then 'Order delivered with delay of few days '
                when delivery_days > 30 then 'Order delivered with delay of a month'
                else "order not delivered yet"
            End delivery_comment
from delivery_details;   

/* 9) Write a SQL query to display the total payment_value for the payments done by ‘voucher’ or ‘credit card’ for all the payment_value 
which are less than the average payment_value. */

select PAYMENT_TYPE , sum(payment_value) from payment where PAYMENT_TYPE in ('voucher','credit_card') and 
payment_value < (select avg(PAYMENT_value) from payment where  PAYMENT_TYPE in ('voucher','credit_card')) group by payment_type; 

/* 10) Write a SQL query To display the cutomer_ID, Order_ID, Customer_city and define a new column “city name length” where if name of the city 
i) has < 8 characters then it is ‘small’ ii) more than 8 and less than 15 it is ‘medium’ iii) for any other large values “large” for all the matching 
values in the 2 tables */

with city_detail as (select customer_id, customer_city,length(customer_city) city_length, order_id  
from customer c join order1 o using (customer_id))
select *, case
			when city_length< 8 then 'Small'
            when city_length< 15 then 'Medium' 
            else 'Large'
		end length_tag 
from city_detail; 		
