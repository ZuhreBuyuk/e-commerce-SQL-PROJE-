/* SQL PROJE */



/*

Case 1 : Sipariş Analizi
-Aylık olarak order dağılımını inceleyiniz. Tarih verisi için order_approved_at kullanılmalıdır. 

SQL Query:
*/

 

SELECT
    EXTRACT(YEAR FROM order_approved_at) AS year,
    EXTRACT(MONTH FROM order_approved_at) AS month,
    COUNT(*) AS order_count
FROM
orders
GROUP BY
year,
month
ORDER BY
year,
month;


/*  

Case 1 : Sipariş Analizi
-Aylık olarak orderstatuskırılımındaorder sayılarını inceleyiniz.
Sorgu sonucunda çıkan outputuexcel ile görselleştiriniz.
Dramatik bir düşüşün ya da yükselişin olduğu aylar var mı? Veriyi inceleyerek yorumlayınız.

SQL Query: 
*/


SELECT
   EXTRACT(year FROM order_purchase_timestamp) AS year,
   EXTRACT(month FROM order_purchase_timestamp) AS month,
   order_status,
   COUNT(*) AS order_count
FROM
   orders
GROUP BY
   year, month, order_status
ORDER BY
   year, month, order_status;


/* 

Case 1 : Sipariş Analizi
-Ürün kategorisi kırılımında sipariş sayılarını inceleyiniz. Özel günlerde öne çıkan kategoriler nelerdir? Örneğin yılbaşı, sevgililer günü…

SQL Query: 

*/

WITH special_day_orders AS (
    SELECT
oi.product_id,
p.product_category_name,
        DATE_TRUNC('day', o.order_purchase_timestamp) AS order_date,
        CASE
            WHEN DATE_TRUNC('day', o.order_purchase_timestamp) BETWEEN '2016-12-15' AND '2024-12-31' THEN 'Yılbaşı Dönemi'
            WHEN DATE_TRUNC('day', o.order_purchase_timestamp) BETWEEN '2016-02-01' AND '2024-02-14' THEN 'Sevgililer Günü Dönemi'
            ELSE 'Diğer'
        END AS special_day_name
    FROM
orders o
    JOIN
order_itemsoi ON o.order_id = oi.order_id
    JOIN
products p ON oi.product_id = p.product_id
    WHERE
        DATE_TRUNC('day', o.order_purchase_timestamp) BETWEEN '2016-12-01' AND '2024-12-31' -- Örneğin, Aralık ayı için siparişler
        OR DATE_TRUNC('day', o.order_purchase_timestamp) BETWEEN '2016-01-25' AND '2024-02-14' -- Örneğin, Ocak ayı sonu ve Şubat ayı başı için siparişler
        OR DATE_TRUNC('day', o.order_purchase_timestamp) = '2016-02-14' -- Sevgililer Günü
)
SELECT
special_day_name AS "Özel Gün",
product_category_name AS "Ürün Kategorisi",
    COUNT(DISTINCT product_id) AS "Sipariş Sayısı"
FROM
special_day_orders
GROUP BY
special_day_name,
product_category_name
ORDER BY
special_day_name,
    "Sipariş Sayısı" DESC;


/*


Case 1 : Sipariş Analizi
-Haftanın günleri(pazartesi, perşembe, ….) ve ay günleri (ayın 1’i,2’si gibi) bazında order sayılarını inceleyiniz. Yazdığınız sorgunun outputu ile excel’de bir görsel oluşturup yorumlayınız.

SQL Query: 


*/

SELECT
    EXTRACT(ISODOW FROM order_purchase_timestamp) AS day_of_week,
    CASE
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 1 THEN 'Monday'
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 2 THEN 'Tuesday'
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 3 THEN 'Wednesday'
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 4 THEN 'Thursday'
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 5 THEN 'Friday'
        WHEN EXTRACT(ISODOW FROM order_purchase_timestamp) = 6 THEN 'Saturday'
        ELSE 'Sunday'
    END AS weekday_name,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY day_of_week
ORDER BY day_of_week


/*

Grafiği incelediğimizde müşteriler en çok Pazartesi günü alışveriş yapmaktadır. 
Bunun sebebi psikolojik bir neden olabilir. 
Pazartesi sendromunu atlatmak için alışveriş yapmak yaralı görünebilir.
Hafta sonu az olmamasının sebebi insanların genellikle dışarda olmaları ve e- ticareti tercih etmemelileridir.

 

SQL Query: 

*/

SELECT

    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    COUNT(order_id) AS order_count
FROM
orders
GROUP BY

month
ORDER BY

month;


/*


Case 2 : Müşteri Analizi 
-Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 

Örneğin; Sibel Çanakkale’den 3, Muğla’dan 8 ve İstanbul’dan 10 sipariş olmak üzere 3 farklı şehirden sipariş veriyor. Sibel’in şehrini en çok sipariş verdiği şehir olan İstanbul olarak seçmelisiniz ve Sibel’in yaptığı siparişleri İstanbul’dan 21 sipariş vermiş şekilde görünmelidir.

SQL Query: 

*/


WITH CustomerMaxOrderCity AS (
    SELECT
c.customer_id,
c.customer_city AS max_order_city,
        COUNT(o.order_id) AS total_orders
    FROM
customers c
    JOIN
orders o ON c.customer_id = o.customer_id
    WHERE
o.order_status = 'delivered'
    GROUP BY
c.customer_id,
c.customer_city
),
CityTotalOrders AS (
    SELECT
max_order_city,
        SUM(total_orders) AS total_orders
    FROM
CustomerMaxOrderCity
    GROUP BY
max_order_city
)
SELECT
cmoc.max_order_city AS city,
cto.total_orders
FROM
CustomerMaxOrderCitycmoc
JOIN
CityTotalOrderscto ON cmoc.max_order_city = cto.max_order_city
GROUP BY
cmoc.max_order_city,
cto.total_orders
ORDER BY
cto.total_orders DESC;



/*



Case 3: Satıcı Analizi
-Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

SQL Query: 


*/

WITH FastestSellers AS (
    SELECT
oi.seller_id,
        AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_approved_at)) / 86400) AS avg_delivery_time,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM
orders o
    JOIN
order_itemsoi ON o.order_id = oi.order_id
    WHERE
o.order_status = 'delivered'
    GROUP BY
oi.seller_id
    HAVING
        COUNT(DISTINCT o.order_id) > 1 -- Birden fazla farklı sipariş olmalı
    ORDER BY
avg_delivery_time ASC
    LIMIT 5
)
SELECT
fs.seller_id,
fs.avg_delivery_time AS average_delivery_time,
fs.order_count,
    COALESCE(COUNT(DISTINCT r.review_id), 0) AS review_count,
    COALESCE(AVG(r.review_score), 0) AS average_score
FROM
FastestSellersfs
LEFT JOIN
order_itemsoi ON fs.seller_id = oi.seller_id
LEFT JOIN
reviews r ON oi.order_id = r.order_id
GROUP BY
fs.seller_id,
fs.avg_delivery_time,
fs.order_count
ORDER BY
fs.avg_delivery_time ASC;





/*


Case 3: Satıcı Analizi
-Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 
 Fazla kategoriye sahip satıcıların order sayıları da fazla mı? 

SQL Query: 
	

*/


WITH seller_product_categories AS (
    SELECT
oi.seller_id,
        COUNT(DISTINCT p.product_category_name) AS category_count
    FROM
order_itemsoi
    LEFT JOIN
products p ON oi.product_id = p.product_id
    GROUP BY
oi.seller_id
)
SELECT
spc.seller_id,
spc.category_count,
    COUNT(oi.order_id) AS order_count
FROM
seller_product_categoriesspc
LEFT JOIN
order_itemsoi ON spc.seller_id = oi.seller_id
GROUP BY
spc.seller_id, spc.category_count
ORDER BY
spc.category_count DESC;



/*


Case 4 : Payment Analizi
-Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.

SQL Query: 

*/

WITH installment_counts AS (
    SELECT
o.customer_id,
        COUNT(p.payment_installments) AS installment_count,
c.customer_city,
c.customer_state
    FROM
orders o
    INNER JOIN
payments p ON o.order_id = p.order_id
    INNER JOIN
customers c ON o.customer_id = c.customer_id
    GROUP BY
o.customer_id, c.customer_city, c.customer_state
)
SELECT
ic.customer_city,
ic.customer_state,
    AVG(ic.installment_count) AS avg_installment_count
FROM
installment_countsic
GROUP BY
ic.customer_city, ic.customer_state
ORDER BY
avg_installment_count DESC
LIMIT 5;


/*


Case 4 : Payment Analizi
-Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.




SQL Query: 

*/

SELECT
p.payment_type,
    COUNT(DISTINCT o.order_id) AS successful_order_count,
    SUM(p.payment_value) AS total_successful_payment_amount
FROM
payments p
JOIN
orders o ON p.order_id = o.order_id
JOIN
order_itemsoi ON o.order_id = oi.order_id
JOIN
productspr ON oi.product_id = pr.product_id
WHERE
p.payment_value = oi.price + oi.freight_value
GROUP BY
p.payment_type
ORDER BY
    COUNT(DISTINCT o.order_id) DESC;

/*

Case 4 : Payment Analizi
-Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

SQL Query: 


*/

	WITH installment_orders AS (
    SELECT
oi.product_id,
p.payment_type,
        COUNT(DISTINCT o.order_id) AS installment_order_count
    FROM
order_itemsoi
    JOIN
payments p ON oi.order_id = p.order_id
    JOIN
orders o ON oi.order_id = o.order_id
    WHERE
p.payment_type IN ('credit_card', 'boleto') -- Tek çekim ve taksitli ödemeler
    GROUP BY
oi.product_id, p.payment_type
),
product_categories AS (
    SELECT
oi.product_id,
p.product_category_name
    FROM
order_itemsoi
    JOIN
products p ON oi.product_id = p.product_id
)
SELECT
pc.product_category_name,
    SUM(io.installment_order_count) AS total_installment_orders
FROM
installment_ordersio
JOIN
product_categoriespc ON io.product_id = pc.product_id
GROUP BY
pc.product_category_name
ORDER BY
    SUM(io.installment_order_count) DESC;



/*


se 5 : RFM Analizi

Aşağıdaki e_commerce_data_.csv doyasındaki veri setini kullanarak RFM analizi yapınız. 
Recency hesaplarken bugünün tarihi değil en son sipariş tarihini baz alınız. 

SQL Query: 

*/

WITH rfm_table AS (
    SELECT
customer_id,
        EXTRACT(DAY FROM CURRENT_DATE - MAX(invoicedate)) AS Recency,
        COUNT(DISTINCT invoiceno) AS Frequency,
        SUM(quantity * unitprice) AS Monetary
    FROM
rfm
    GROUP BY
customer_id
)
SELECT
customer_id,
Recency,
Frequency,
Monetary,
    NTILE(5) OVER (ORDER BY Recency) AS R_Score,
    NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
    NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
FROM
rfm_table;



