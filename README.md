# Handwritted Digit Recognition implemented in pure SQL
![Header Image](https://github.com/lszel/SQL-Neural-Network/blob/main/img/header.jpg)


Author: László Szél

Date: 2021-02-01

I was created a siple neural network for handwritten digit recognition, and it is implemented in pure SQL. The image transformation from MNIST sample data to database records are implemented in SQL too.

The trainig and the test samples are downloadable mnist training and test files from here:
http://yann.lecun.com/exdb/mnist/

The files:
* http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz:  training set images (9912422 bytes)
* http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz:  training set labels (28881 bytes)
* http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz:   test set images (1648877 bytes)
* http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz:   test set labels (4542 bytes) 

Extract them to a folder, for example to /home/centos/mnist or you can copy them into the data directory of the mariadb directly.

You can check some enviroment settings with the sql script: 01_check_before_run.sql

If the sample data is visible for the mariadb, than you can create the database itself. The next sql will creates the database objects (tables, views, procedures and functions), uploads the sample data, and transform it into records.: 02_create_environment.sql



With the next sql you can set the size of layers, and it creates the neurons and the weigths.
03_create_environment.sql



If the network is ready, you can initiate the learning with a command:

call learn(number of cycles, learning rate);

for eyxample:
call learn(100,0.01);