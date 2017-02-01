DELIMITER $$
DROP PROCEDURE IF EXISTS `pr_order_food` $$
CREATE DEFINER=`dev_user`@`%` PROCEDURE `pr_order_food`(IN i_seat_no INT,IN i_item MEDIUMTEXT,IN i_quantities MEDIUMTEXT,OUT o_order_message VARCHAR(200))
BEGIN
  DECLARE item TEXT DEFAULT NULL;
  DECLARE quantity TEXT DEFAULT NULL;
  DECLARE quantity_length INT DEFAULT NULL;
  DECLARE item_length INT DEFAULT NULL;
  DECLARE trim_item TEXT DEFAULT NULL;
  DECLARE trim_quantity TEXT DEFAULT NULL;
  DECLARE temp INT;
  CALL pr_check_seats ();
  
  
IF EXISTS(SELECT seat_id  FROM seat_status  WHERE seat_id = i_seat_no AND seat_status = 'AVAILABLE') AND (SELECT seat_status.`seat_state` FROM seat_status WHERE seat_status.`seat_id`=i_seat_no)=FALSE  
/*Check seat is available or not*/
THEN

		UPDATE seat_status
		SET seat_state= NOT seat_state
		WHERE seat_status.`seat_id`=i_seat_no;
	
	
	INSERT INTO order_detail(seat_number) VALUES(i_seat_no);
  
  SET temp = ( LENGTH(i_item) - LENGTH(REPLACE(i_item, ',', ''))) + 1;
		IF temp <=  (SELECT limits FROM order_limit)/*Checking whether given item within 5 items or not*/
  THEN iterator :
		LOOP /*Spliting the given input item and quantity*/
			IF LENGTH(TRIM(i_item)) = 0 OR i_item IS NULL
			THEN LEAVE iterator;
			END IF;
		SET item = SUBSTRING_INDEX(i_item, ',', 1);
		SET quantity = SUBSTRING_INDEX(i_quantities, ',', 1);
		SET item_length = LENGTH(item);
		SET quantity_length = LENGTH(quantity);
		SET trim_item = TRIM(item);
		SET trim_quantity = TRIM(quantity);
				
		CALL pr_check_food (i_seat_no, item, quantity,@o_message);/*Check whether food is available or not*/
		SET o_order_message=(SELECT @o_message);
		
		SET i_item = INSERT(i_item, 1, item_length + 1, '');
		SET i_quantities = INSERT(i_quantities, 1, quantity_length + 1, '');
		END LOOP;
		ELSE
	        SELECT 'Sorry you can order only 5 items'  INTO o_order_message;
		END IF;

	
  ELSE
  SELECT 'Sorry the seat is not available at the moment'  INTO o_order_message;
  END IF;
END$$
DELIMITER ;



DROP PROCEDURE IF EXISTS `pr_check_food`;
DELIMITER $$

CREATE DEFINER=`dev_user`@`%` PROCEDURE `pr_check_food`(IN i_seat_no INT,IN i_item VARCHAR(50),IN i_ordered_quantity INT, OUT o_message VARCHAR(1000))
BEGIN
DECLARE item_remaining INT;
    IF EXISTS(SELECT fn_get_item_id(i_item))/*Get item id from function within scheduled time*/
		THEN
			IF EXISTS (SELECT food_menu.`id` FROM food_menu WHERE  food_menu.`id`=(SELECT fn_get_item_id(i_item)))/*check whether the item id is valid or not*/
			THEN
			
			SET item_remaining=(SELECT food_stock.`quantity` FROM food_stock WHERE food_stock.`item_id`=(SELECT food_menu.`id` FROM food_menu WHERE food_menu.`id`=(SELECT fn_get_item_id(i_item))));
				IF (item_remaining>=i_ordered_quantity)/*Check stock is available or not*/
				THEN
					UPDATE food_stock
					SET quantity=quantity-i_ordered_quantity
					WHERE food_stock.`item_id`=(SELECT id FROM food_menu WHERE food_menu.`item`=i_item AND food_menu.`id`=(SELECT fn_get_item_id(i_item)) ); 
					
					UPDATE seat_status
					SET seat_status='BOOKED',
					taken_time=CURRENT_TIME()
					WHERE seat_status.`seat_id`=i_seat_no; 
		
					
					INSERT INTO hotel_transaction(order_id,menu_id,quantity,order_time,order_date,STATUS) VALUES ((SELECT order_id FROM order_detail WHERE order_detail.`seat_number`=i_seat_no ORDER BY order_id DESC LIMIT 1 ),(SELECT food_menu.`id` FROM food_menu WHERE food_menu.`id`=(SELECT fn_get_item_id(i_item))),i_ordered_quantity,CURRENT_TIME(),CURDATE(),'DELIVERED');
					SELECT CONCAT(i_item,' Deliverd Successfully') INTO o_message;
				ELSE
				SELECT CONCAT('Sorry the ',i_item,' you have ordered is out of stock at now')  INTO o_message;
				END IF;
			ELSE
			SELECT CONCAT(i_item,' will not be served at the moment.Check the item you have ordered is available in menu')  INTO o_message;
			END IF;
		ELSE
		SELECT CONCAT(i_item,' is currently not available. Please order something else')  INTO o_message;
		END IF;
END$$
DELIMITER ;

DELIMITER $$

USE `ashwini_db`$$

DROP PROCEDURE IF EXISTS `pr_cancel_order`$$

CREATE DEFINER=`dev_user`@`%` PROCEDURE `pr_cancel_order`(IN i_seat_no INT,IN i_item VARCHAR(50),OUT o_cancel_message VARCHAR(200))
BEGIN
DECLARE ordered_time TIME;
DECLARE transaction_id INT;
DECLARE order_id INT;
SET order_id = (SELECT hotel_transaction.`order_id` FROM hotel_transaction  WHERE hotel_transaction.`menu_id`=(SELECT fn_get_item_id(i_item))  ORDER BY hotel_transaction.`order_id` DESC LIMIT 1);	        
SET ordered_time=(SELECT SUBTIME(CURRENT_TIME(),'0:00:10.000'));
SET transaction_id=(SELECT hotel_transaction.`id` FROM hotel_transaction WHERE hotel_transaction.`order_id`=order_id AND hotel_transaction.`menu_id`=(SELECT (fn_get_item_id(i_item))) AND hotel_transaction.`order_time` BETWEEN ordered_time AND CURRENT_TIME());
	/*Check whether the item is in schedule timing and given input is valid seat or not */
	IF EXISTS (SELECT transaction_id) THEN
		IF EXISTS (SELECT id FROM  hotel_transaction WHERE  hotel_transaction.`order_time` BETWEEN ordered_time AND CURRENT_TIME()) 
		THEN
			IF EXISTS (SELECT id FROM  hotel_transaction WHERE hotel_transaction.`status`='DELIVERED' AND hotel_transaction.`id`=transaction_id) /*Check whether the valid delivered item is entered for cancel if not display already cancelled*/
			THEN 
			START TRANSACTION;
			SET autocommit=0;
			UPDATE food_stock
			SET quantity=quantity+(SELECT quantity FROM hotel_transaction WHERE hotel_transaction.`id`=transaction_id)
			WHERE food_stock.`item_id`=(SELECT hotel_transaction.`menu_id` FROM hotel_transaction WHERE hotel_transaction.`id`=transaction_id);
			UPDATE hotel_transaction
			SET hotel_transaction.`status`='CANCELLED'
			WHERE hotel_transaction.`id`=transaction_id;
			SELECT CONCAT(i_item,' you have ordered is cancelled at now') INTO o_cancel_message;
			COMMIT;
			/*Make seat available if all the order was cancelled*/
				IF NOT EXISTS(SELECT hotel_transaction.`order_id` FROM hotel_transaction WHERE hotel_transaction.`order_id`=order_id AND hotel_transaction.`status`='DELIVERED')
				THEN 
				UPDATE seat_status
				SET seat_status.`seat_status`='AVAILABLE',seat_state=FALSE
				WHERE seat_status.`seat_id`=i_seat_no;
				END IF;
			ELSE
			SELECT CONCAT(i_item,'is already cancelled') INTO o_cancel_message;
			END IF;
		ELSE
		SELECT 'Sorry you could not cancel your order since your order time got excced above 10 seconds' INTO o_cancel_message;
		END IF;
	ELSE 
	SELECT 'Please enter valid seat number or item to cancel' INTO o_cancel_message;
	END IF;
END$$

DELIMITER ;

DELIMITER $$

USE `ashwini_db`$$

DROP PROCEDURE IF EXISTS `pr_check_seats`$$

CREATE DEFINER=`dev_user`@`%` PROCEDURE `pr_check_seats`()
BEGIN
DECLARE take_time TIME;
DECLARE X INT;
SET X=1;
WHILE X<=(SELECT COUNT(seat_id)FROM seat_status)
DO
SET take_time=(SELECT taken_time FROM seat_status WHERE seat_id=X);
/*Book the seat for 30 minutes when the order is delivered and make the seat to available after 30 seconds*/
IF (take_time<(SELECT SUBTIME(CURRENT_TIME(),'0:00:30.000')))
THEN
UPDATE seat_status
SET seat_status='AVAILABLE',seat_state=FALSE,taken_time=CURRENT_TIME()
WHERE seat_id=X;
END IF;
SET X=X+1;
END WHILE;
IF ((SELECT CURRENT_TIME()) BETWEEN '00:00:00' AND '07:00:00')/*Refill the stock to next day when the day starts*/
THEN
UPDATE food_stock
SET quantity=(SELECT food_schedule.`quantity` FROM food_schedule WHERE food_stock.`schedule_id`= food_schedule.`id`);
END IF;
END$$

DELIMITER ;
/*Get the item id for the item ordered with scheduled time*/


DELIMITER $$
CREATE PROCEDURE pr_add_item(IN i_id INT,IN i_item VARCHAR(50), IN i_schedule_type VARCHAR(50),OUT o_item_message VARCHAR(50))
BEGIN
DECLARE type_id INT;
DECLARE quantities INT;
SET type_id = (SELECT food_schedule.`id` FROM food_schedule WHERE food_schedule.`schedule_type`=i_schedule_type);
SET quantities = (SELECT food_schedule.`quantity` FROM food_schedule WHERE food_schedule.`schedule_type`=i_schedule_type); 
INSERT INTO food_menu(id,item) VALUES(i_id,i_item);
INSERT INTO food_stock(item_id,schedule_id,quantity) VALUES (i_id,type_id,quantities);
SELECT 'Item Added Successfully' INTO o_item_message;
END $$
DELIMITER ;
