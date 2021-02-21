USE mnist;

drop function if exists CLIP;
DELIMITER $$
CREATE FUNCTION CLIP(x float) RETURNS float
    READS SQL DATA
    DETERMINISTIC
    BEGIN
        RETURN LEAST(GREATEST(x, -500),  500);
    END$$
DELIMITER ;

drop function if exists RectifiedLinearUnit;
DELIMITER $$
CREATE FUNCTION RectifiedLinearUnit (x float)
RETURNS float
BEGIN
   RETURN if(x>0,x,0);
END$$
DELIMITER ;

drop function if exists RectifiedLinearUnit_Derivative;
DELIMITER $$
CREATE FUNCTION RectifiedLinearUnit_Derivative (x float)
RETURNS float
BEGIN
   RETURN if(x>0,1,0);
END$$
DELIMITER ;

DROP function IF EXISTS `sigmoid`;
DELIMITER $$
CREATE FUNCTION `sigmoid` (x float)
RETURNS float
BEGIN
   RETURN 1 / (1 + EXP(clip(-x)));
END$$
DELIMITER ;


DROP function IF EXISTS `sigmoid_derivative`;
DELIMITER $$
CREATE FUNCTION `sigmoid_derivative` (x float)
RETURNS float
BEGIN   
   set @S=exp(clip(x));
   RETURN @s / pow(1+@s,2);
END$$
DELIMITER ;


DROP function IF EXISTS `hiperbolictangent`;
DELIMITER $$
USE `mnist`$$
CREATE FUNCTION `hiperbolictangent` (x float) RETURNS float
BEGIN
  set @exp2x :=   exp(clip(-2 * x));
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