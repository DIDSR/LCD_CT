#Suggested correction by Dhaval Kadia
conda create --name octave -y
conda activate octave
conda install -c conda-forge octave -y
conda install -c conda-forge cxx-compiler -y

export CC="$(which gcc)"
export CXX="$(which g++)"

mkoctfile -p CC
mkoctfile -p CXX

octave --eval 'pkg install -forge image; pkg install https://github.com/apjanke/octave-tablicious/releases/download/v0.4.5/tablicious-0.4.5.tar.gz; pkg load image tablicious'

# Original commands  made by Brandon nelson
#conda create --name octave -y
#conda activate octave
#conda install -c conda-forge octave -y
#conda install -c conda-forge cxx-compiler -y

#octave --eval 'pkg install -forge image; pkg install https://github.com/apjanke/octave-tablicious/releases/download/v0.4.5/tablicious-0.4.5.tar.gz; pkg load image tablicious'
