#  before start the script!!!!
#  modify the ownership of the downloadad files for mysql user to be able to load 
# for example:
#  chown -R mysql:mysql /home/centos/mnist/
# and set the initial parameters:

#  check selinux or apparmor status if the file load not works, or try to copy the files into the default mysql directory (/var/lib/mysql)  

#  location of the downloaded mnist files
set @mnist_path='/var/lib/mysql/'; 

# set packet size to 64MByte be able to load the bigest (45M)  file
#SET GLOBAL max_allowed_packet=67108864;
# set packet size to 1G be able to load the bigest (45M)  file
SET GLOBAL max_allowed_packet=1073741824;

# grant file privileges to user
#grant file ON *.*  to 'student'@'%';
#flush privileges;

SET SESSION storage_engine = MyISAM;
set global innodb_file_per_table=1;
SET sql_mode = '';

#  creation of mnist database
DROP DATABASE IF EXISTS mnist;
CREATE SCHEMA `mnist` ;
 
USE mnist;

#  tricky view of numbers from 0 to 9999999
CREATE VIEW `numbers` AS
    SELECT 
        x1.N + x10.N * 10 + x100.N * 100 + x1000.N * 1000 + x10000.N * 10000 + x100000.N * 100000 + x1000000.N * 1000000 AS num
    FROM
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x1,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x10,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x100,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x1000,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x10000,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x100000,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) x1000000;
        
        
#  numbers table, it is a faster than using the view      
DROP TABLE IF EXISTS `numbers_table`;
create table `numbers_table` as
select *
from  numbers;  
ALTER TABLE `numbers_table` 
ADD PRIMARY KEY (`num`);  
    

#  create temporary table for data files
drop table if exists `mnist_data_loader` ;
CREATE TABLE `mnist_data_loader` (
    `id` INT(11) NOT NULL,
    `name` VARCHAR(45) DEFAULT NULL,
    `data` LONGBLOB DEFAULT NULL,
    PRIMARY KEY (`id`)
)  ENGINE=MYISAM DEFAULT CHARSET=UTF8MB4;

#  enable file load
SET SQL_SAFE_UPDATES = 0;

#  prepare some files before load
truncate `mnist_data_loader`;
INSERT INTO `mnist_data_loader` (`id`, `name`, `data`) VALUES ('1', 'train_images',LOAD_FILE( concat(@mnist_path,'train-images.idx3-ubyte')));
INSERT INTO `mnist_data_loader` (`id`, `name`, `data`) VALUES ('2', 'train_labels',LOAD_FILE( concat(@mnist_path,'train-labels.idx1-ubyte' )));
INSERT INTO `mnist_data_loader` (`id`, `name`, `data`) VALUES ('3', 'test_images',LOAD_FILE( concat(@mnist_path, 't10k-images.idx3-ubyte')));
INSERT INTO `mnist_data_loader` (`id`, `name`, `data`) VALUES ('4', 'test_labels',LOAD_FILE( concat(@mnist_path,'t10k-labels.idx1-ubyte' )));


# Split test images blob data into separate records:
set @source='test_images';
set @max=(select  ascii(substr(data,7,1)) * 256 + ascii(substr(data,8,1))  from  mnist_data_loader  where name=@source);

DROP TABLE IF EXISTS `test_images`;
create table `test_images` as
select 
  id_list.character_id as id,
   (substr(data,17+id_list.character_id*784,784)) as "image"
from
  mnist_data_loader,
  (SELECT num character_id from numbers_table where num<@max)  as id_list
where 
    name=@source;
    
ALTER TABLE `test_images` 
ADD PRIMARY KEY (`id`),
ADD UNIQUE INDEX `id_UNIQUE` (`id` ASC);    
    
# convert test labels data  into a table:
set @source='test_labels';
set @max=(select  ascii(substr(data,7,1)) * 256 + ascii(substr(data,8,1))  from  mnist_data_loader  where name=@source);

DROP TABLE IF EXISTS `test_labels`;
create table `test_labels` as
select 
  id_list.character_id as id,
   ascii(substr(data,9+id_list.character_id,1)) as "label"
from
  mnist_data_loader,
  (SELECT num character_id from numbers_table where num<@max)  as id_list
where 
    name=@source;
    
ALTER TABLE `test_labels` 
ADD PRIMARY KEY (`id`);        
    
  # Split train images blob data into separate records:
set @source='train_images';
set @max=(select  ascii(substr(data,7,1)) * 256 + ascii(substr(data,8,1))  from  mnist_data_loader  where name=@source);

DROP TABLE IF EXISTS `train_images`;
create table `train_images` as
select 
  id_list.character_id as id,
   (substr(data,17+id_list.character_id*784,784)) as "image"
from
  mnist_data_loader,
  (SELECT num character_id from numbers_table where num<@max)  as id_list
where 
    name=@source;  
    
ALTER TABLE `mnist`.`train_images` 
ADD PRIMARY KEY (`id`),
ADD UNIQUE INDEX `id_UNIQUE` (`id` ASC);
    
    
# convert train labels data  into a table:
set @source='train_labels';
set @max=(select  ascii(substr(data,7,1)) * 256 + ascii(substr(data,8,1))  from  mnist_data_loader  where name=@source);

DROP TABLE IF EXISTS `train_labels`;
create table `train_labels` as
select 
  id_list.character_id as id,
   ascii(substr(data,9+id_list.character_id,1)) as "label"
from
  mnist_data_loader,
  (SELECT num character_id from numbers_table where num<@max)  as id_list
where 
    name=@source;
    
ALTER TABLE `mnist`.`train_labels` 
ADD PRIMARY KEY (`id`);    


# data loader table no longer required
drop table mnist_data_loader;


# create view for train data ( split info to pixel by pixel related to image ID, and info about which input neuron will be affected)
CREATE OR REPLACE VIEW `train_matrix` AS
    SELECT 
        train_images.id AS image_id,
        num AS n_id,
            (ASCII(SUBSTR(train_images.image, num, 1)))/256 AS input
        #   (ASCII(SUBSTR(train_images.image, num, 1))) AS input
    FROM
        numbers_table,
        `train_images`
    WHERE
        num <= 784;
        
CREATE OR REPLACE VIEW test_matrix AS
    SELECT 
        test_images.id AS image_id,
        n.num AS n_id,
      (ASCII(SUBSTR(test_images.image,n.num,1)))/256 AS `input`
       #   (ASCII(SUBSTR(test_images.image,n.num,1))) AS `input`
    FROM
        (numbers_table n
        JOIN test_images)
    WHERE
        n.num <= 784;        
   
# create view for train results ( put the label value into a proper row (value 1 the not proper rowa are 0 )
CREATE OR REPLACE VIEW `result_matrix` AS
    SELECT 
        num+(select min(n_id) from neurons where layer_id=(select max(layer_id) from neurons)) as n_id,
        id AS image_id,
        num AS result_id,
        IF(num = label, 1, 0) AS output
    FROM
        numbers_table,
        train_labels
    WHERE
        num < 10
    ORDER BY image_id , num;
    
    
CREATE OR REPLACE VIEW test_result_matrix AS
    SELECT 
        numbers_table.num + (SELECT 
                MIN(neurons.n_id)
            FROM
                neurons
            WHERE
                neurons.layer_id = (SELECT 
                        MAX(neurons.layer_id)
                    FROM
                        neurons)) AS n_id,
        test_labels.id AS image_id,
        numbers_table.num AS result_id,
        IF(numbers_table.num = test_labels.label,
            1,
            0) AS `output`
    FROM
        (numbers_table
        JOIN test_labels)
    WHERE
        numbers_table.num < 10
    ORDER BY test_labels.id , numbers_table.num;   