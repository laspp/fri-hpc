# Using storage nodes with ARC and XRSL

This demo explains how to use storage nodes available in the grid. Storage nodes are usefull for medium term storage of data that would be used repeatedly because they eliminate the need to always copy the same data into / out of the grid. Demo was executed on jost.arnes.si, using dcache.arnes.si as a storage node.

Requirements:
* Valid certificate to enable access to SLING
* ARC client installed on login node
* VO membership (gen.vo.sling.si was used in testing)

## Data manipulation commands in ARC

Following is a summary of ARC commands used to manipulate data on storage nodes. Full command descriptions can be found in [ARC Clients User Manual](http://www.nordugrid.org/documents/arc-ui.pdf).

### arcls
List directory contents.
Use -l to get more verbose output.
```
arcls -l gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/
```

### arccp
Copy data to / from storage node (also works inside the node itself).
Source / destination can be storage node, local computer (the one running the command) or server using one of the supported protocols.
```
arccp ./test_file.txt gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/

arccp gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_file.txt ./test_file_2.txt
```

### arcrename
Rename a file.
```
arcrename gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_file.txt gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_file_2.txt
```

### arcmkdir
Create a new directory.
If parent does not exist behaviour is protocol dependent. If -p switch is used missing parents are created.
```
arcmkdir gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_dir
```

### arcrm
Delete file or empty directory
```
arcrm gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_file_2.txt

arcrm gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/test_dir
```

## Using storage nodes with XRSL

XRSL parameters _inputFiles_ and _OutputFiles_ accept storage node URLs for source / destination just like they would any other URL. See [Extended Resource Specification Language
Reference Manual](http://www.nordugrid.org/documents/xrsl.pdf) for more usage details.

```
(rsl_substitution=("STORAGE_PATH" "gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test"))

(inputFiles=
    ("input_copied_from_local"   "local_input")
    ("input_copied_from_storage" $(STORAGE_PATH)/storage_input)
)

(outputFiles=
    ("output_copied_to_local"  "local_output")
    ("output_copied_to_storage $(STORAGE_PATH)/storage_output)
)
```

## Demo usage

Demo will create a new directory in _gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si_ (_storage_test_ by default). Before submitting the job it is advisable to check storage node contents using
```
arcls gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si
```
If directory _storage_test_ exists open _storage_test.xrsl_ and change it to something else (edit line 2 in _storage_test.xrsl_)

Make sure _storage_test.xrsl_, _append_text.sh_ and _input_file.txt_ exist in the current directory and submit the job by running
```
arcsub -c jost.arnes.si storage_test.xrsl
```

Wait for the job to finish (you can monitor its progress using _arcstat_).

After the job is done retrieve its outputs using _arcget_.

_output_file.txt_ should start with the line "Following are the contents of the input file:", followed by input file.

Output file will also be copied to storage node. Fetch it using
```
arccp gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/output_file.txt ./output_from_storage.txt
```
Verify that _output_file.txt_ and _output_from_storage.txt_ are the same.

Clean up by deleting data, that was created on the storage node
```
arcrm gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test/output_file.txt
arcrm gsiftp://dcache.arnes.si/data/arnes.si/gen.vo.sling.si/storage_test
```

If you changed directory _storage_test_ to something else remember to update the above commands accordingly.
