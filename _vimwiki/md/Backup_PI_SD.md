Something like this:

Code: Select all
```
    sudo fdisk -l
```

Take note of how the SD card is identified.
In my case it is /dev/sdb1.
Then:

Code: Select all
```
    sudo dd bs=4M if=/dev/sdb | gzip > /home/your_username/image`date +%d%m%y`.gz
```


This will compress the image using gzip.
To restore the backup on SD card:

Code: Select all
```
    sudo gzip -dc /home/your_username/image.gz | dd bs=4M of=/dev/sdb
```
