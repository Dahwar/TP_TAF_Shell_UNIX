
init(){
    if [ -d "./taf" ]; then
        rm -f ./taf/*
        rmdir ./taf
    fi
    echo "Initialisation effectuee";
}

dlTafPays(){
    if [ ! -d "./taf" ]; then
        mkdir "./taf"
    fi

    if [ -f "./taf/$1-text.txt" -a -f "./taf/$1.txt" ]; then
        echo "Fichiers deja telecharges"
    else
        curl "http://wx.rrwx.com/taf-$1.htm" > "./taf/$1.txt"
        curl "http://wx.rrwx.com/taf-$1-txt.htm" > "./taf/$1-text.txt"
        echo "Telechargement termine"
    fi
}

extractTaf(){
    if [ -f "./taf/$1-text.txt" -a -f "./taf/$1.txt" ]; then
        aerop=`grep -i "$2" < "./taf/$1.txt" | awk -F "<b>" '{print $2}' | cut -d "<" -f1`
        if [ ! -z "$aerop" ]; then
            grep "$aerop" < "./taf/$1-text.txt" > "./taf/taf.txt"
        fi
    else
        echo "Fichiers non trouvees"
    fi
}

analyse(){
    echo "Analyse et generation du rapport en cours..."
    
    codeSource="<!DOCTYPE html><html><head><title>TAF</title></head><body><h2>TAF</h2><ul>"
    mois=`date "+%m"`
    
    tafTemp=$(cat "./taf/taf.txt")
    
    set $tafTemp

    echo "Analyse : $1" # Airport
    airport="$1"
    codeSource="$codeSource<li>Airport : $1</li>"
    shift
    
    if [ "$1" = "AMD" ]; then # in case of TAF AMD
        echo "Analyse : $1"
        shift
    fi
    
    echo "Analyse : $1" # Emitted
    codeSource="$codeSource<li>Emitted : ${1:0:2}/$mois @ ${1:2:2}H${1:4:3}</li>"
    shift
    
    while [ ! -z "$1" ]; do

        echo "Analyse : $1"
        var="$1" #create var, and reset to "" when we catch it with a regex, to avoid that a second regex catch it
        
        if [ ! `expr "$var" : '^\([+-]\{0,1\}[A-Z]\{2\}\{1,\}\)$'` = "" ]; then #Weather
            codeSource="$codeSource<li>Weather : $1</li>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^\([0-9]\{4\}/[0-9]\{4\}\)$'` = "" ]; then #Periode
            codeSource="$codeSource<li>Periode : ${1:0:2}/$mois @ ${1:2:2}H00Z .. ${1:5:2}/$mois @ ${1:7:2}H00Z</li>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^\([A-Z0-9]*KT\)$'` = "" ]; then #Wind
            if [ "${1:5:1}" = "G" ]; then
                codeSource="$codeSource<li>Wind : ${1:0:3} @ ${1:3:2} Gusting ${1:6:2} KT</li>"
            else
                codeSource="$codeSource<li>Wind : ${1:0:3} @ ${1:3:2} KT</li>"
            fi
            var=""
        fi
        
        if [ ! `expr "$var" : '^\([0-9]\{4\}\)$'` = "" ]; then #Horizontal visibility
            if [ "$1" = "9999" ]; then
                codeSource="$codeSource<li>Horizontal visibility > 10000 m</li>"
            else
                codeSource="$codeSource<li>Horizontal visibility : $1 m</li>"
            fi
            var=""
        fi
        
        if [ ! `expr "$var" : '^\([A-Z]\{3\}[0-9]\{3\}\)'` = "" ]; then #Clouds
            typeClouds="${1:0:3}"
            cloudsHauteur=`expr "${1:3:3}00" : '[0]\{0,2\}\([0-9]\{3,5\}\)'`
            
            case "$typeClouds" in
                "SKC") typeClouds="clear";;
                "FEW") typeClouds="few";;
                "SCT") typeClouds="scattered";;
                "BKN") typeClouds="broken";;
                "OVC") typeClouds="overcast";;
                *) echo "$var : Type de nuage inconnu";;
            esac
            
            codeSource="$codeSource<li>Clouds : $typeClouds @ $cloudsHauteur ft</li>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^\(CAVOK\)$'` = "" ]; then #CAVOK
            codeSource="$codeSource<li>Clouds : OK</li>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^\(TEMPO\)$'` = "" ]; then #TEMPO
            codeSource="$codeSource</ul><h2>Temporary</h2><ul>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^\(BECMG\)$'` = "" ]; then #BECMG
            codeSource="$codeSource</ul><h2>Becoming</h2><ul>"
            var=""
        fi
        
        if [ ! `expr "$var" : '^PROB\([0-9]\{2\}\)$'` = "" ]; then #Probality
            codeSource="$codeSource</ul><h2>Probality ${1:4:2}%</h2><ul>"
            var=""
        fi
        
        shift
    done
        
    codeSource="$codeSource</ul></body></html>"
    
    echo "$codeSource"> "./taf/taf-$airport.html"
    
    echo "Analyse et generation du rapport termine"
    
    if [ -f "./taf/buffer.txt" ]; then
        rm -f ./taf/buffer.txt
    fi
    
    if [ -f "./taf/taf.txt" ]; then
        rm -f ./taf/taf.txt
    fi    

}

run(){
    dlTafPays $1
    extractTaf $1 "$2"
    analyse
}

multiple(){
    run "$1" "$2"
    echo `cat "./taf/taf-planDeVol.html" "./taf/taf-$airport.html"` > "./taf/taf-planDeVol.html"
    
    if [ -f "./taf/taf-$airport.html" ]; then
        rm -f "./taf/taf-$airport.html"
    fi
    
}

initT(){
        if [ ! -d "./taf" ]; then
            mkdir "./taf"
        fi
    
        if [ -f "./taf/taf-planDeVol.html" ]; then
            rm -f "./taf/taf-planDeVol.html"
        fi
        
        touch "./taf/taf-planDeVol.html"
}

while [ $# != 0 ]; do
    case "$1" in
        -i) init
            shift;;
        -d) dlTafPays $2
            shift 2;;
        -e) extractTaf $2 "$3"
            shift 3;;
        -a) analyse
            shift;;
        -p) run $2 "$3"
            shift 3;;
        -t) initT
            while [ ! -z "$*" ]; do 
                if [ ! -z "$2" -a ! -z "$3" ]; then
                    multiple "$2" "$3"
                fi
                shift
                shift
            done;;
        *) echo "Erreur" 1>&2 ;;
    esac
done