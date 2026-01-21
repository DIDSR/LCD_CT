conda create --name octave -y
conda activate octave
conda install -c conda-forge octave -y
conda install -c conda-forge cxx-compiler -y

octave --eval 'pkg install -forge image; pkg install https://github.com/apjanke/octave-tablicious/releases/download/v0.4.5/tablicious-0.4.5.tar.gz; pkg load image tablicious'