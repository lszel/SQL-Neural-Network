DROP procedure IF EXISTS `show_image`;
DELIMITER $$
USE `mnist`$$
CREATE PROCEDURE `show_image`(IN image_id integer, IN image_group varchar(255) )
BEGIN
set @header_offset=16;
set @image_offset=28*28*image_id+@header_offset;
SELECT 
    numbers_table.num,
    HEX(SUBSTR(data,
                numbers_table.num * 28 + @image_offset,
                29))
FROM
    mnist_data_loader,
    numbers_table
WHERE
    numbers_table.num < 29 AND 
    name = image_group
ORDER BY numbers_table.num;
END$$
DELIMITER ;   