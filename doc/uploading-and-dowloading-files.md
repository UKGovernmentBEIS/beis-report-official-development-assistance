# Uploading and Downloading Files

## Uploading files

- to copy a file to the required remote environment:

```
cat RELATIVE-PATH/FILENAME.csv | cf ssh beis-roda-ENVIRONMENT -c "cat > FILENAME.csv"
```

Note: `cat` cannot create a directory. This command will fail if a path is passed to `cat >` . This also means that the copied file will be found in the **root** of the remote project; you will need to move the file to the required directory after copying. 

## Downloading files

Occasionally you might need to download one or more files from a remote, for example if you have run a process in a remote environment that creates a file that you want to have a local copy of. 

- connect to the required remote project and copy the file:
```
cf ssh beis-roda-ENVIRONMENT --command "cat /app/tmp/remote_file.txt" > ./local_file.txt
```
