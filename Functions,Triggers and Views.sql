/*Get the item id for the item ordered with scheduled time*/
DELIMITER $$
CREATE FUNCTION fn_get_item_id(f_item VARCHAR(30))
RETURNS INT
BEGIN
DECLARE item_id INT;
SET item_id=(SELECT food_stock.`item_id` FROM food_menu JOIN food_stock ON food_stock.`item_id`=food_menu.`id` JOIN food_schedule ON food_stock.`schedule_id` =food_schedule.`id` WHERE food_menu.`item`=f_item AND CURRENT_TIME() BETWEEN available_from_time AND available_to_time);
RETURN item_id;
END; $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER food_seat_status
AFTER INSERT ON  seed_hotel_seats
FOR EACH ROW
BEGIN
INSERT INTO seat_status(seat_id,STATUS,taken_time) VALUES(new.id,'available','00:00:00');
END $$
DELIMITER ;


/*Show the current stock to the customer whenever they needed*/
CREATE VIEW v_stock_review AS SELECT item_id,item,quantity FROM food_stock,food_menu  WHERE food_menu.`id`=food_stock.`item_id`;

SELECT * FROM v_stock_review
