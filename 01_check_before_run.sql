#  checking setup

#  before start the script!!!!
#  modify the ownership of the downloaded files for mysql user to be able to load 
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

# check packet size settings   
select  'Packet Size' as `Check`, if(@@max_allowed_packet<1073741824, 'Must to change the my.cnf!', 'ok') as Result
union
# check file availability  
SELECT 'Train Images file availability',If(ISNULL(LOAD_FILE( concat(@mnist_path,'train-images.idx3-ubyte'))),'not available','ok')
union
SELECT 'Train Labels file availability',If(ISNULL(LOAD_FILE( concat(@mnist_path,'train-labels.idx1-ubyte' ))),'not available','ok')
union
SELECT 'Test Image file availability',If(ISNULL(LOAD_FILE( concat(@mnist_path, 't10k-images.idx3-ubyte'))),'not available','ok')
union
SELECT 'Test Labels file availability',If(ISNULL(LOAD_FILE( concat(@mnist_path,'t10k-labels.idx1-ubyte' ))),'not available','ok');
