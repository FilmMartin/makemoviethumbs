# Frame extractor 1.2
# Extracts still frames from a video at regular intervals 
# Filename includes the (approximate) timestamp of the video

# Original coding by Tim Pozar, www.lns.com
# Adapted by Martin Weiss, 2016, www.weiss.no

#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
outdir="."
inputfile=""
interval_secs=0
starttime=0
endtime=0
average=0
filetype="png"

show_help ()
{
    echo "$0:"
    echo "   -h (show help)"
    echo "   -f inputfile"
    echo "   -d output_directory ('$outdir' is the default)"
    echo "   -i interval_secs"
    echo "   -s starttime_secs"
    echo "   -e endtime_secs"
    echo "   -a total_images_averaged_over_the_duration_or_start_stop_time (will override interval_secs)"
    echo "   -t type of fileformat (jpg, png, bmp; png as default)"
}

while getopts "h?f:i:s:e:a:d:t:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    f)  inputfile=$OPTARG
        ;;
    d)  outdir=$OPTARG
        ;;
    i)  interval_secs=$OPTARG
        ;;
    s)  starttime=$OPTARG
        ;;
    e)  endtime=$OPTARG
        ;;
    a)  average=$OPTARG
        ;;
	t)	filetype=$OPTARG
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [ -z $inputfile ]; then
   echo Please specify an input video file
   show_help
   exit 1
fi

if [ $endtime -eq 0 ]; then
   # When used to calculate average intervals or end time is not defined...
   endtime=`ffprobe -i $inputfile -show_entries format=duration -v quiet -of csv="p=0" | sed 's/\..*//'`
fi

if [ $average -gt 0 ]; then
   let duration=endtime-starttime
   let interval_secs=duration/average
fi

# Get the filename sans directory...
filename=`echo $inputfile | sed 's/.*\///'`
# Drop off the filename extesion...
filename="${filename/.mp4/}"

echo -e "Creating thumbnails... \c"

# Create sequence and use the filename for the images to avoid collision with other image processing...
ffmpeg -loglevel panic -i $inputfile -ss $starttime -t $endtime -f image2 -qscale 2 -vf fps=1/$interval_secs $filename-%d.$filetype

# Get a listing of the thumbnail filenames...
arr=( $(ls $filename*.$filetype) )
# Number of filenames
qnt=${#arr[@]}
# First filename will be #1..
echo -e "Adding timestamp to file names... \c"
i=1
while [ $i -le $qnt ]; do
    let totalsec=i*interval_secs
    let timestampsecs=totalsec+starttime-interval_secs/2  # correct(ish) calculation of TC (1 frame too high)
    let sec=(timestampsecs % 60)
    let min=(timestampsecs % 3600)/60
    let hour=timestampsecs/3600
    thumb_filename=$(printf "%s-%02d_%02d_%02d-%d.$filetype" "$filename" "$hour" "$min" "$sec" "$interval_secs")
    mv $filename-$i.$filetype $outdir/$thumb_filename
    let i=i+1
done
let i=i-1
echo -e "Done. Created "$i" thumbnails."
