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


DROP function IF EXISTS `asciiart`;
DELIMITER $$
USE `mnist`$$
CREATE DEFINER=`student`@`%` FUNCTION `asciiart`(s varchar(255)) RETURNS varchar(255) CHARSET latin1
BEGIN
set @i =0;
set @y='';
while @i < length(s)  do    
    set @x=ascii( substr(s,@i,1)  );
    set @y = concat( @y, substr(" .:-=+*#%@",round(@x*10/255+1),1) );    
    set @i=@i+1;
end while;
   
RETURN @y; 
END$$
DELIMITER ;