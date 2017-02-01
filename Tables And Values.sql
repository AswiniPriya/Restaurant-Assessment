CREATE TABLE `food_menu` ( 
 `id` INT(11) NOT NULL,
 `item` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  ENGINE=INNODB DEFAULT CHARSET=utf8
  
  CREATE TABLE `food_schedule` ( 
  `id` INT(11) NOT NULL,
  `schedule_type` VARCHAR(50) NOT NULL,
  `available_from_time` TIME NOT NULL,
  `available_to_time` TIME NOT NULL,
  `quantity` INT(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UNIQUE` (`schedule_type`)) ENGINE=INNODB DEFAULT CHARSET=utf8

  INSERT INTO food_schedule VALUES(1,'Breakfast','08:00:00','11:00:00',100),
  (2,'Lunch','11:15:00','15:00:00',75),
  (3,'Refreshment','15:15:00','23:00:00',200),
  (4,'Dinner','19:00:00','23:00:00',100);

  CREATE TABLE `food_stock` (`
  id` INT(11) NOT NULL AUTO_INCREMENT,
  `item_id` INT(11) NOT NULL,
  `schedule_id` INT(11) NOT NULL,
  `quantity` INT(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),  KEY `item_id_fk` (`item_id`),
  KEY `schedule_id_fk` (`schedule_id`),
  CONSTRAINT `item_id_fk` FOREIGN KEY (`item_id`)
  REFERENCES `food_menu` (`id`),
  CONSTRAINT `schedule_id_fk` FOREIGN KEY (`schedule_id`)
  REFERENCES `food_schedule` (`id`)) ENGINE=INNODB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8
   
CREATE TABLE `order_limit` (
`id` INT(11) NOT NULL,
`limits` INT(11) NOT NULL,
PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8

INSERT INTO order_limit VALUES(1,5);

CREATE TABLE `order_detail` (
`order_id` INT(11) NOT NULL AUTO_INCREMENT,
`seat_number` INT(11) NOT NULL,
PRIMARY KEY (`order_id`),
KEY `seat_number_fk` (`seat_number`),
CONSTRAINT `seat_number_fk` FOREIGN KEY (`seat_number`) 
REFERENCES `seat_status` (`id`)) ENGINE=INNODB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8
           
 CREATE TABLE `seat_status` (
`id` INT(11) NOT NULL AUTO_INCREMENT,
`seat_id` INT(11) NOT NULL,
`seat_status` VARCHAR(30) NOT NULL,
`seat_state` tinyint(1) NOT NULL DEFAULT '0',
`taken_time` TIME NOT NULL,  PRIMARY KEY (`id`),
KEY `seat_id_fk` (`seat_id`),
CONSTRAINT `seat_id_fk` FOREIGN KEY (`seat_id`)
REFERENCES `seed_hotel_seats` (`id`)) ENGINE=INNODB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8

INSERT INTO seat_status(seat_id,STATUS) VALUES (1,'available'),
(2,'available'),(3,'available'),(4,'available'),(5,'available'),
(6,'available'),(7,'available'),(8,'available'),(9,'available'),(10,'available');

             
CREATE TABLE `seed_hotel_seats` (
`id` INT(11) NOT NULL,
`seat_name` VARCHAR(10) NOT NULL,
PRIMARY KEY (`id`)) ENGINE=INNODB DEFAULT CHARSET=utf8

INSERT INTO seed_hotel_seats VALUES(1,table1),(2,table2),(3,table3),
(4,table4),(5,table5),(6,table6),(7,table7),(8,table8),(9,table9),(10,table10);


CREATE TABLE `hotel_transaction` ( 
`id` INT(11) NOT NULL AUTO_INCREMENT,
`order_id` INT(11) NOT NULL, 
`menu_id` INT(11) NOT NULL,
`quantity` INT(11) NOT NULL, 
`order_time` TIME NOT NULL, 
`order_date` DATE NOT NULL, 
`status` VARCHAR(50) NOT NULL,
PRIMARY KEY (`id`),  
KEY `menu_id_fk` (`menu_id`),  
KEY `order_id_fk` (`order_id`),
CONSTRAINT `order_id_fk` FOREIGN KEY (`order_id`) REFERENCES `order_detail` (`order_id`), 
CONSTRAINT `menu_id_fk` FOREIGN KEY (`menu_id`) REFERENCES `food_menu` (`id`),  
ENGINE=INNODB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8    