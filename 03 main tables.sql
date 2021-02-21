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
  `error_derivative` float DEFAULT 0,
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