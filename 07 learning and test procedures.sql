USE mnist;

DROP procedure IF EXISTS `calculate_layer_relu`;
DELIMITER $$
CREATE PROCEDURE `calculate_layer_relu` (IN layer_id integer)
BEGIN
update neurons n
JOIN forward_propagation_values_relu fpv on n.n_id=fpv.n_id
set n.predicted=fpv.calculated_output
where n.layer_id=layer_id;
END$$
DELIMITER ;

DROP procedure IF EXISTS `calculate_layer_sig`;
DELIMITER $$
CREATE PROCEDURE `calculate_layer_sig` (IN layer_id integer)
BEGIN
update neurons n
JOIN forward_propagation_values_sig fpv on n.n_id=fpv.n_id
set n.predicted=fpv.calculated_output
where n.layer_id=layer_id;
END$$
DELIMITER ;


DROP procedure IF EXISTS `prepare_train`;
DELIMITER $$
CREATE PROCEDURE `prepare_train`(IN input_image integer)
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
  
END$$
DELIMITER ;


DROP procedure IF EXISTS `prepare_test`;
DELIMITER $$
CREATE PROCEDURE `prepare_test`(IN input_image integer)
BEGIN
  SET SQL_SAFE_UPDATES = 0;
   
  # set the input values to the predicted 'port' of the input neurons 
  UPDATE neurons
  JOIN  test_matrix ON neurons.n_id = test_matrix.n_id 
  SET  neurons.predicted = test_matrix.input
  WHERE  test_matrix.image_id = input_image;

  # set the result values to the expected 'port' of the output neurons 
  update neurons n
  join result_matrix r on n.n_id=r.n_id
  set n.expected=r.output
  where image_id= input_image;
  
END$$
DELIMITER ;



DROP procedure IF EXISTS `forward`;
DELIMITER $$
CREATE PROCEDURE `forward`()
BEGIN   
  #  forward propagation
  call calculate_layer_sig(1);
  call calculate_layer_sig(2);
  call calculate_layer_sig(3);  
END$$
DELIMITER ;



DROP procedure IF EXISTS `back`;
DELIMITER $$
CREATE PROCEDURE `back`(IN alpha float)
BEGIN
  SET SQL_SAFE_UPDATES = 0;
    
UPDATE neurons n 
  join neuron_delta_sig nd on nd.n_id=n.n_id
 SET 
     n.delta = (nd.new_delta)    
    -- n.delta = (`n`.`predicted` - `n`.`expected`) * (`n`.`predicted` * (1 - `n`.`predicted`))
 WHERE
    n.layer_id = 3;
   
update     
  neurons n 
 join neuron_delta_hidden_sig ndh on ndh.n_id=n.n_id
 SET 
     -- n.delta = (ndh.new_delta)*n.predicted*(1-n.predicted)	
     n.delta = (ndh.new_delta)
 WHERE
    n.layer_id = 2;           
    
 update     
  neurons n 
 join neuron_delta_hidden_sig ndh on ndh.n_id=n.n_id
 SET 
     -- n.delta = (ndh.new_delta)*n.predicted*(1-n.predicted)	
     n.delta = (ndh.new_delta)
 WHERE
    n.layer_id = 1;       
 
 update weights w
  join neurons n on n.n_id=w.n_id_out
  join neurons ni on ni.n_id=w.n_id_in 
  set w.w = w.w - (alpha * n.delta * ni.predicted);  
  
update neurons n  
  join weights w on w.n_id_out=n.n_id    
  join neurons ni on ni.n_id=w.n_id_in
  set n.bias = n.bias - (alpha * n.delta )
  where n.layer_id>0;
  
  
END$$
DELIMITER ;


DROP procedure IF EXISTS `train_batch`;
DELIMITER $$
CREATE PROCEDURE `train_batch`(in label_id integer,in batch_max integer, in alpha float)
BEGIN 
    DECLARE b INT Default 0 ;
	declare image_id int default 0;
        
    batch_loop: loop
        set b=b+1;       
             
             set image_id=(select id from train_labels where label=label_id order by rand() limit 1 );
             
             call prepare_train(image_id);
             call forward();           
             call back(alpha);
             
             sET @row_start = (select min(n_id) from neurons where layer_id=3); 
             set @max_predicted = (select max(predicted) from neurons where layer_id=3);    
             set @predicted = (select n_id-@row_start value from neurons  where  layer_id=3 and predicted=@max_predicted limit 1);
             set @expected = (select n_id-@row_start value from   neurons  where   layer_id=3 and expected=1);
             set @accuracy=squared_error(3);
                INSERT INTO `train_accuracy_log` (`accuracy`, `predicted`, `expected`) VALUES (@accuracy,@predicted,@expected);             
         
         IF b>=batch_max THEN
           LEAVE batch_loop;    
        END IF;
           END LOOP batch_loop;  
END$$
DELIMITER ;

DROP procedure IF EXISTS `train`;
DELIMITER $$
CREATE PROCEDURE `train`(in max integer,in batch_max integer, in alpha float)
BEGIN 
   DECLARE a INT Default 0 ;
   
   declare sample int default 0;
  
   simple_loop: LOOP
      SET a=a+1;		      
         
         set sample=round(rand()*9);
         call train_batch(sample, batch_max, alpha);       
        
      IF a=max THEN
          LEAVE simple_loop;
       END IF;
   END LOOP simple_loop;
END$$
DELIMITER ;



DROP procedure IF EXISTS `test_batch`;
DELIMITER $$
CREATE PROCEDURE `test_batch`(batch_max integer)
BEGIN 
    DECLARE b INT Default 0 ;
	declare image_id int default 0;
        
    batch_loop: loop
        set b=b+1;       
             
             -- set image_id=(select id from train_labels where label=label_id order by rand() limit 1 );
             set image_id=round(rand()*10000);
             call prepare_test(image_id);
             call forward();           
             -- call back(alpha);
             
             sET @row_start = (select min(n_id) from neurons where layer_id=3); 
             set @max_predicted = (select max(predicted) from neurons where layer_id=3);    
             set @predicted = (select n_id-@row_start value from neurons  where  layer_id=3 and predicted=@max_predicted limit 1);
             set @expected = (select n_id-@row_start value from   neurons  where   layer_id=3 and expected=1);
             set @accuracy=squared_error(3);
                INSERT INTO `test_accuracy_log` (`accuracy`, `predicted`, `expected`) VALUES (@accuracy,@predicted,@expected);             
         
         IF b>=batch_max THEN
           LEAVE batch_loop;    
        END IF;
           END LOOP batch_loop;  
END$$
DELIMITER ;
