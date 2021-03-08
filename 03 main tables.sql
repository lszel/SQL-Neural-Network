SET SESSION storage_engine = MyISAM;
set global innodb_file_per_table=1;
SET sql_mode = '';

USE mnist;
    
 # create neurons table   
 CREATE TABLE `neurons` (
  `n_id` int(11) NOT NULL,
  `layer_id` int(11) DEFAULT NULL,
  `bias` float DEFAULT 0,
  `predicted` float DEFAULT 0,
  `expected` float DEFAULT 0,
  `delta` float DEFAULT 0,
  PRIMARY KEY (`n_id`),
  KEY `layer` (`layer_id`)
) ;

# create weights table 
CREATE TABLE `weights` (
  `w_id` int(11) NOT NULL,
  `n_id_in` int(11) DEFAULT NULL,
  `n_id_out` int(11) DEFAULT NULL,
  `w` float DEFAULT 0,
  PRIMARY KEY (`w_id`),
  KEY `n_id_in` (`n_id_in`),
  KEY `n_id_out` (`n_id_out`)
) ;  

CREATE TABLE `train_accuracy_log` (
  `step` INT NOT NULL AUTO_INCREMENT,
  `accuracy` FLOAT NULL,
  `predicted` INT NULL,
  `expected` INT NULL,
  PRIMARY KEY (`step`),
  UNIQUE INDEX `step_UNIQUE` (`step` ASC) )
ENGINE = MyISAM;


CREATE TABLE `test_accuracy_log` (
  `step` INT NOT NULL AUTO_INCREMENT,
  `accuracy` FLOAT NULL,
  `predicted` INT NULL,
  `expected` INT NULL,
  PRIMARY KEY (`step`),
  UNIQUE INDEX `step_UNIQUE` (`step` ASC) )
ENGINE = MyISAM;  



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