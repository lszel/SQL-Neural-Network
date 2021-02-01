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

#  creation of mnist database
DROP DATABASE IF EXISTS mnist;
CREATE SCHEMA `mnist` ;
 
USE mnist;

#  tricky table, it is a view of numbers from 0 to 9999999
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
select 
  *
from
  numbers;  
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
ADD UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE;    
    
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
ADD UNIQUE INDEX `id_UNIQUE` (`id` ASC) VISIBLE;
    
    
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

    
    
# Create the 'working' part of the database
    
    
 # create neurons table   
 CREATE TABLE `neurons` (
  `n_id` int(11) NOT NULL,
  `layer_id` int(11) DEFAULT NULL,
  `bias` float DEFAULT 0,
  `predicted` float DEFAULT 0,
  `expected` float DEFAULT 0,
  `error_derivative` float DEFAULT 0,
  PRIMARY KEY (`n_id`),
  KEY `layer` (`layer_id`)
) ;

create view neuron_delta as 
select 
   *,
   (n.expected-n.predicted)*(n.predicted*(1-n.predicted)) delta
from 
    neurons n;

# create weights table 
CREATE TABLE `weights` (
  `w_id` int(11) NOT NULL,
  `n_id_in` int(11) DEFAULT NULL,
  `n_id_out` int(11) DEFAULT NULL,
  `w` float DEFAULT 0,
  `delta` float DEFAULT 0,
  PRIMARY KEY (`w_id`),
  KEY `n_id_in` (`n_id_in`),
  KEY `n_id_out` (`n_id_out`)
) ;  


DROP function IF EXISTS `sigmoid`;
DELIMITER $$
CREATE FUNCTION `sigmoid` (x float)
RETURNS float
BEGIN
   RETURN 1 / (1 + EXP(-x));
END$$
DELIMITER ;


DROP function IF EXISTS `sigmoid_derivative`;
DELIMITER $$
CREATE FUNCTION `sigmoid_derivative` (x float)
RETURNS float
BEGIN
   set @S=exp(x);
   RETURN @s / pow(1+@s,2);
END$$
DELIMITER ;


DROP function IF EXISTS `hiperbolictangent`;
DELIMITER $$
USE `mnist`$$
CREATE FUNCTION `hiperbolictangent` (x float) RETURNS float
BEGIN
  set @exp2x :=   exp(-2 * x);
RETURN (1 - @exp2x) / (1 + @exp2x);
END;$$
DELIMITER ;


DROP function IF EXISTS `hiperbolictangent_derivative`;
DELIMITER $$
USE `mnist`$$
CREATE FUNCTION `hiperbolictangent_derivative` (x float) RETURNS float
BEGIN
RETURN  1 - pow(HiperbolicTangent(x),2);
END$$
DELIMITER ;


CREATE VIEW `neuron_error_derivative` AS
select
   n.n_id,
  sum(ne.error_derivative*w.w) * sigmoid_derivative(n.predicted) error_derivative
 from
  neurons n
  join weights w on w.n_id_in = n.n_id
  join neurons ne on ne.n_id=w.n_id_out
group by n.n_id;  


CREATE VIEW forward_propagation_values AS
    SELECT 
        n.n_id AS n_id,
        n.predicted,
         SIGMOID(SUM(ni.predicted * w.w) + n.bias) AS `calculated_output`
    #    hiperbolictangent(SUM(ni.predicted * w.w) + n.bias) AS `calculated_output`
    FROM
        weights w
        JOIN neurons n  on n.n_id = w.n_id_out
        JOIN neurons ni on ni.n_id = w.n_id_in
    GROUP BY n.n_id;
    
    
    
CREATE 
VIEW back_propagation_values AS
 SELECT    
   n.n_id,
   sum(w.w*nd.delta) delta
FROM
    neurons n
    join weights w on w.n_id_in=n.n_id
    join neuron_delta nd on nd.n_id=w.n_id_out
group by n.n_id;


create view bias_propagation_values as
SELECT    
   n.n_id,
   sum(nd.delta) delta
FROM
    neurons n
    join weights w on w.n_id_in=n.n_id
    join neuron_delta nd on nd.n_id=w.n_id_out
group by n.n_id;





# create view for train data ( split info to pixel by pixel related to image ID, and info about which input neuron will be affected)
CREATE OR REPLACE VIEW `train_matrix` AS
    SELECT 
        train_images.id AS image_id,
        num AS n_id,
        ASCII(SUBSTR(train_images.image, num, 1)) AS input
    FROM
        numbers_table,
        `train_images`
    WHERE
        num <= 784;
        
CREATE OR REPLACE VIEW test_matrix AS
    SELECT 
        test_images.id AS image_id,
        numbers_table.num AS n_id,
        ASCII(SUBSTR(test_images.image,
                numbers_table.num,
                1)) AS `input`
    FROM
        (numbers_table
        JOIN test_images)
    WHERE
        numbers_table.num <= 784;        
   
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


# Create the 'working' part of the database


DROP procedure IF EXISTS `propagate`;
DROP procedure IF EXISTS `learn`;

DELIMITER $$
CREATE PROCEDURE `propagate`(IN input_image integer, IN alpha float)
BEGIN

SET SQL_SAFE_UPDATES = 0;
   
# set the input values to the predicted 'port' of the input neurons 
UPDATE neurons
JOIN  train_matrix ON neurons.n_id = train_matrix.n_id 
SET  neurons.predicted = train_matrix.input
WHERE  train_matrix.image_id = input_image;

# set the result values to the expected 'port' of the output neurons 
update neurons n
join result_matrix r on n.n_id=r.n_id
set n.expected=r.output
where image_id= input_image;

#  forward propagation

# calculate layer 1
update neurons n
JOIN forward_propagation_values fpv on n.n_id=fpv.n_id
set n.predicted=fpv.calculated_output
where n.layer_id=1;

# calculate layer 2
update neurons n
JOIN forward_propagation_values fpv on n.n_id=fpv.n_id
set n.predicted=fpv.calculated_output
where n.layer_id=2;

# calculate layer 3
update neurons n
JOIN forward_propagation_values fpv on n.n_id=fpv.n_id
set n.predicted=fpv.calculated_output
where n.layer_id=3;

# calculate layer 3 error derivative
update neurons n
 set n.error_derivative= (n.predicted - n.expected) * sigmoid_derivative(  n.predicted  )
# set n.error_derivative= abs(n.predicted - n.expected) * hiperbolictangent_derivative(  n.predicted  )
where n.layer_id=3;

# back propagation 

update neurons n
  join neuron_error_derivative ned on ned.n_id = n.n_id
  set n.error_derivative = ned.error_derivative
where n.layer_id=2;

update neurons n
  join neuron_error_derivative ned on ned.n_id = n.n_id
  set n.error_derivative = ned.error_derivative
where n.layer_id=1;

update neurons n
set n.bias = n.bias - alpha * n.error_derivative;


update weights w
join neurons n on n.n_id=w.n_id_out
set w.w = w - alpha * n.error_derivative;
   
END$$



DELIMITER $$
CREATE PROCEDURE `learn`(in max integer, in alpha float)
BEGIN 
   DECLARE a INT Default 0 ;
      
   simple_loop: LOOP
      SET a=a+1;
    
        call propagate(round(rand()*60000),alpha);
         IF a=max THEN
            LEAVE simple_loop;
         END IF;
   END LOOP simple_loop;
END$$