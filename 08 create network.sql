 # create network

SET SQL_SAFE_UPDATES = 0;
set @input_neurons_count=784;  #28*28
set @output_neurons_count=10;
set @hidden_layers_count=2;
set @hidden_layer1_size=300;
set @hidden_layer2_size=300;


truncate test_accuracy_log;
truncate train_accuracy_log;
truncate `neurons`;

# create input neurons
set @last_id=@input_neurons_count;
insert into `neurons` ( `n_id`, `layer_id`,  `bias`)
select
  id.num as n_id,
  0 as layer_id,
  0 as bias
from
   (select num from numbers_table where num<=@last_id)  id;
   
 # create 1. hidden layer neurons  
insert into `neurons` ( `n_id`, `layer_id`,  `bias`)
select
  id.num as n_id,
  1 as layer_id,
   (rand()*2-1)/@hidden_layer1_size as bias
  -- as bias
  #rand()*2-1 as bias
from
   (select num from numbers_table where num>@last_id and num<=@last_id+@hidden_layer1_size)  id;
 set @last_id=@last_id+@hidden_layer1_size;  
 
  # create 2. hidden layer neurons  
insert into `neurons` ( `n_id`, `layer_id`,  `bias`)
select
  id.num as n_id,
  2 as layer_id,
   (rand()*2-1)/@hidden_layer2_size as bias
  -- as bias
  #rand()*2-1 as bias
from
   (select num from numbers_table where num>@last_id and num<=@last_id+@hidden_layer2_size)  id;
 set @last_id=@last_id+@hidden_layer2_size; 
 
# create output neurons  
insert into `neurons` ( `n_id`, `layer_id`,  `bias`)
select
  id.num as n_id,
  3 as layer_id,
  0 as bias
from
   (select num from numbers_table where num>@last_id and num<=@last_id+@output_neurons_count)  id;
 
truncate `weights`;   
# create weights  
SET @row_number = 0; 

insert into `weights` ( `w_id`, `n_id_in`,  `n_id_out`,  `w`)
SELECT 
 (@row_number:=@row_number + 1) AS w_id, 
  n_in.n_id,
  n_out.n_id,
  (rand()*2-1) w  

from
  neurons n_in,
  neurons n_out
where
  n_in.layer_id = n_out.layer_id-1;   