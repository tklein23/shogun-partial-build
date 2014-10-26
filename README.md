# how to use

Assuming that shogun checked out current working directory.  SHOGUN partial build is checked out to `../shogun-partial-build/`.

```
rm -rf build-quick/
git checkout . 
../shogun-partial-build/shogun-classes-cleanup.sh src/shogun/lib/SGNDArray.h src/shogun/io/SerializableAsciiFile.h src/shogun/io/SerializableHdf5File.h src/shogun/kernel/CustomKernel.h src/shogun/classifier/svm/OnlineLibLinear.h
../shogun-partial-build/shogun-build.sh build-quick --skip-tests
```
