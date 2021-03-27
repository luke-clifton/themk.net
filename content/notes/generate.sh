#! /bin/sh

dest=$1
src=$(pwd)

echo Moving CSS files...
cp $src/*.css $dest

for i in $(ls $src/*.md)
do
	file=$(basename $i .md)
	echo Converting $file.md to $file.html
	pandoc --mathjax --section-divs -c pandoc.css $i -o $dest/$file.html -t html5
done
