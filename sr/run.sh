#!/bin/bash
runit="local"
product="dockersr"
os=$1
metode=$2
usebranch=$3

filejson="work/config.json" 
filejson_res="todo/config.backup"

switchbc="1.0"
switcres="1.0"

version_gchash="unknown";
version_rshash="unknown";

# Clone Data
if [ "$os" = "data" ];then

 echo "Start clone data..."

 if [ "$metode" = "core" ];then
  echo "~ Get Core"
  git clone https://github.com/akbaryahya/YuukiSR YuukiSR
 fi
 if [ "$metode" = "res" ];then
  echo "~ Get Resources"
  git clone https://gitlab.com/yukiz/SR_Resources SR_Resources
 fi
 echo "EXIT NOW"
 exit 1
fi

# Get Data if not found
if [ ! -d "SR_Resources" ]; then  
  echo "No Found Resources, let's clone first"
  sh run.sh data res
fi

# OS
if [ -z "$os" ]; then
 os="local"
fi

# Metode
if [ -z "$metode" ]; then
 metode="build"
fi

# Branch Switch Version
if [ "$usebranch" = "0" ];then
 switchbc="1.0"
 switcres="1.0"
fi

echo OS: $os - Metode: $metode - Branch:$switchbc

# Check SR
cd YuukiSR

# Switch
#ls -a
branch_now=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$branch_now" ]; then
 echo "Error get name branch"
 exit 1
fi
# if HEAD
if [ "$branch_now" = "HEAD" ];then
 echo "This seems to work on GitHub Action, or first time? so let's switch to original to check version";
 # $branch_now = $switchbc
fi
if [ "$switchbc" != "$branch_now" ]; then
 echo "Switch $branch_now to $switchbc"
 git switch $switchbc
else
 echo "You're already there $branch_now"
fi
# Get Hash
version_gchash=$(git rev-parse --short=7 HEAD)
if [ -z "$version_gchash" ]; then
 echo "Error get hash"
 exit 1
fi
# Back to home
cd ..

# Check Resources (Only if need with metode res)
if [ "$metode" = "res" ];then
 cd SR_Resources
 branch_res_now=$(git rev-parse --abbrev-ref HEAD)
 if [ -z "$branch_res_now" ]; then
  echo "Error get name branch resources"
  exit 1
 fi
 # if HEAD
 if [ "$branch_res_now" = "HEAD" ];then
  echo "This seems to work on GitHub Action, or first time? so let's switch to original to check version";
  # $branch_res_now = $switcres
 fi
 if [ "$switcres" != "$branch_res_now" ]; then
  echo "Switch Resources $branch_res_now to $switcres"
  git switch $switcres
 else
  echo "You're already there resources $branch_res_now"
 fi
 # Get Hash GC
 version_rshash=$(git rev-parse --short=7 HEAD)
 if [ -z "$version_rshash" ]; then
  echo "Error Get Hash Resources"
  exit 1
 fi
 # Back to home
 cd ..
fi

# Copy Hash
echo -n "$version_gchash" > VERSION_SR_$switchbc
if [ "$metode" = "res" ];then
 echo -n "$version_rshash" > VERSION_RS_$switcres
fi

# Copy TMP version
version_last_commit=$os-$switchbc-$version_gchash
version_last_sw=$os-$switchbc
echo $version_last_commit
echo -n "$version_last_commit" > VERSION_TMP

if [ ! -d "work" ]; then
 echo "Make folder work.."
 mkdir -p work
fi
if [ ! -d "todo" ]; then
 echo "Make folder todo.."
 mkdir -p todo
fi

if [ "$metode" = "start" ];then

 if [ "$os" = "local" ];then

  echo "Not yet available for local, because regular folders are complicated"
  exit 1

 else
  ip=$4
  ipdb=$5
  res=$6  
  if [ -z "$ip" ]; then
   ip="127.0.0.1"
  fi
  if [ -z "$ipdb" ]; then
   ipdb="$ip:27017"
  fi
  if [ -z "$res" ]; then
   res="resources_sr_$switchbc"
  fi
  echo "Start Docker with IP $ip"
  docker run \
  --rm -it \
  -v $res:/home/YuukiSR/data \
  -p 22103:22103/udp \
  -p 443:443/tcp \
  -p 80:80/tcp \
  siakbary/$product:$version_last_commit \
  --datebase "mongodb://$ipdb/dockersr" \
  --web_ip "$ip" \
  --game_ip "$ip" \
  --ssl "false" \
  --web_url_ssl "false" \
  --login_password "true"
 fi

fi

# if clean
if [ "$metode" = "clean_work" ];then
 rm -R -f work/*
 rm -R -f .gradle/*
 rm -R -f bin/*
fi

# if sync
if [ "$metode" = "sync" ];then
 cd YuukiSR
 whosm=$4
 getme=$5
 dlrepo=$6
 if [ -z "$dlrepo" ]; then
  dlrepo="CrepeSR"
 fi
 if [ -z "$whosm" ]; then
  whosm="Crepe-Inc"
 fi
 if [ -z "$getme" ]; then
  getme="main"
 fi
 git pull https://github.com/$whosm/$dlrepo.git $getme
 cd ..
fi

if [ "$metode" = "sync_raw" ];then
 cd YuukiSR
 whosm=$4
 getme=$5
 git pull $whosm $getme
 cd ..
fi

# if build
if [ "$metode" = "build" ];then
 
 # if localhost
 if [ "$os" = "local" ];then    

  # Windows User:
  # https://stackoverflow.com/a/49584404 & https://stackoverflow.com/a/64272135  

  # Remove file
  we_clean_it=$4
  if [ "$we_clean_it" = "clean" ];then   
   if test -f "$filejson"; then
    echo "Found file config.json"
    cp -rTf $filejson $filejson_res
   fi
   echo "Remove file work (ending)"   
   rm -R -f work/*
  fi

  echo "Start Bulid..."
  cd YuukiSR

  echo "Update lib stuff"
  npm update

  # Back to home directory
  cd .. 

  echo "Copy file version local"
  cp -rTf VERSION_TMP work/VERSION

 else
  # build local
  # sh run.sh local build $usebranch $4

  # Version Docker
  echo "Copy file version docker"  
  echo -n "$version_last_commit" > work/VERSION

  # Bulid Local
  docker build -t "$product:$version_last_commit" -f os_$os .;
  # Tag to multi source
  echo "Add image to repo public"  
  docker tag "$product:$version_last_commit" "siakbary/$product:$version_last_commit"
  docker tag "$product:$version_last_commit" "siakbary/$product:$version_last_sw"
  # Private Repo
  echo "Add image to private repo"  
  docker tag "$product:$version_last_commit" "repo.yuuki.me/$product:$version_last_commit"
 fi
 
fi

# Push Public
if [ "$metode" = "push" ];then
 docker push siakbary/$product:$version_last_commit
 docker push siakbary/$product:$version_last_sw
fi

# Push Private
if [ "$metode" = "private_push" ];then
 echo "push private"  
 docker push repo.yuuki.me/$product:$version_last_commit
fi