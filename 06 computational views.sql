use mnist;

CREATE OR REPLACE VIEW `neuron_delta_relu` AS
SELECT 
    *,
    (n.predicted - n.expected) *  RECTIFIEDLINEARUNIT_DERIVATIVE(`n`.`predicted`) new_delta
FROM
    neurons n
order by n.n_id;

CREATE OR REPLACE VIEW `neuron_delta_sig` AS
SELECT 
    *,
    (n.predicted - n.expected) *  sigmoid_DERIVATIVE(`n`.`predicted`) new_delta
FROM
    neurons n
order by n.n_id;
    
CREATE OR REPLACE VIEW `neuron_delta_hidden_relu` AS
SELECT 
    n.*,    
    SUM( nou.delta * w.w * RECTIFIEDLINEARUNIT_DERIVATIVE(`n`.`predicted`) )  AS `new_delta`
    -- sum(  (nou.predicted-nou.expected) * (nou.predicted* (1-nou.predicted) )  *  w.w  ) new_delta 
FROM
    neurons n
    join weights w on w.n_id_in=n.n_id
    join neurons nou on nou.n_id=w.n_id_out
group by n.n_id    
order by n.n_id;

CREATE OR REPLACE VIEW `neuron_delta_hidden_sig` AS
SELECT 
    n.*,    
    SUM( nou.delta * w.w * sigmoid_DERIVATIVE(`n`.`predicted`) )  AS `new_delta`
    -- sum(  (nou.predicted-nou.expected) * (nou.predicted* (1-nou.predicted) )  *  w.w  ) new_delta 
FROM
    neurons n
    join weights w on w.n_id_in=n.n_id
    join neurons nou on nou.n_id=w.n_id_out
group by n.n_id    
order by n.n_id;
    

CREATE OR REPLACE VIEW forward_propagation_values_sig AS
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



CREATE OR REPLACE VIEW forward_propagation_values_relu AS
    SELECT 
        n.n_id AS n_id,
        n.predicted,
         RectifiedLinearUnit(SUM(ni.predicted * w.w) + n.bias) AS `calculated_output`
    #    hiperbolictangent(SUM(ni.predicted * w.w) + n.bias) AS `calculated_output`
    FROM
        weights w
        JOIN neurons n  on n.n_id = w.n_id_out
        JOIN neurons ni on ni.n_id = w.n_id_in
    GROUP BY n.n_id;   