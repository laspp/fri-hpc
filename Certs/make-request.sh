#!/usr/bin/env bash

# prerequisites

if ! ssl_loc="$(type -p "openssl")" || [ -z "$ssl_loc" ] ; then
    echo 'OpenSSL not found, prerequisites missing, aborted'
    echo ' (Install OpenSSL package.)'
    exit 1;
fi

# defauls
postform='https://signet-ca.ijs.si/cgi-bin/pub/pki'
keysize=4096
verbose=0
post=0
pin=$(perl -E'print(int rand(10**10))')
formname=''
formemail=''
formdept=''
formphone='xxxx'
#
# sensible web server
type='Web Server'
exkeyusage='serverAuth'
keyusage='digitalSignature, keyEncipherment, dataEncipherment'

function usage {
    echo "
$0:
Generate and optionally post a SiGNET CA PEM certificate request.

USAGE: 
 $0 -h

 $0 [ -c -u -n <type> -k <keysize> -c -p <postargs>] \\
    <email> <org> <ou> <cn>

 $0 [ -c -u -n <type> -k <keysize> -c -p <postargs>] \\
    -d '/C=SI/O=SiGNET/O=Your org/OU=Your OU/CN=Your name or server' <email>

 $0 [ -N <name> -E <email> -D <dept> -T <phone> ] \\
    -P <request file>

 $0 -r <cert-num> -K >private-key-file>


 -h help:      show this help
     
 -d DN:        set explicit distinguished name
               Not starting with /C=SI/O=SiGNET/O= is an error.
               Only one argument, the <email>, is allowed when -d is used.
 -k <size>:    set key size (defaults to 4096, try 2048)
 -c server-client mode:
               request a server-client certificate
 -u user-mode: request a user certificate
               (instead of the default web server certificate)
 -n named:     request a named certificate type (i.e. Mail Server)

 -p post:      post the request directly to the web form
 -P <request>: post a pre-generated request (in PEM form)

Additional arguments with -p and -P (postargs):
 
 -N <name>:    name for direct submission (defaults to CN)
 -E <email>:   email for direct submission (defaults to email)
 -D <dept>:    department for direct submission (defaults to OU)
 -T <phone>:   phone number for direct submission (defaults to xxxx)

Arguments for certificate retrieval:
 -r <cert-no>: certificate number for retrieval
 -K <keyfile>: file to get private key from, typically created when generating request


EXAMPLES

Generate and post a user certificate request:

    $0 -u -p -T 6666 johnny.smith@example.org \\
      'Example Org' IT 'Johnny Smith'

   Results in:

   Distinguished name:       /C=SI/O=SiGNET/O=Example Org/OU=IT/CN=Johnny Smith
   Subject Alternative Name: email: johnny.smith@example.org
   Certificate type:         User certificate
   Form data:                User and department the same, phone 6666

Retrieve the certificate and combine it with the key into browser-importable pkcs12 form
Please use the certificate serial from the web page or the notification email, such as 
1111 in this link:
https://signet-ca.ijs.si:443/cgi-bin/pub/pki?cmd=getcert&key=1111&type=CERTIFICATE

    $0 -r 1111 -k Johnny_Smith-YYYY-MM-DD.key 

    Results in:
      ./Johnny_Smith-YYYY-MM-DD.crt - certificate file in pem format
      ./Johnny_Smith-YYYY-MM-DD.p12 - certificate + encrypted private key for browsers


Post a pre-generated request in PEM format:

    $0 -N 'Johnny Smith' -T 6666 -P request.pem

   Data is extracted from the DN in the request, while 'Johhny Smith' and
   6666 is used as the submitting user and their contact phone number.


Generate and post a server certificate request:

    $0 -p -N 'Johnny Smith' -T 6666 \\
      webmaster@example.org 'Example Org' IT www.example.org
   or
    $0 -p -N 'Johnny Smith' -T 6666 \\
      -d '/C=SI/O=SiGNET/O=Example Org/OU=IT/CN=www.example.org' \\
       webmaster@example.org

   Results in:

   Distinguished name:       /C=SI/O=SiGNET/O=Example Org/OU=IT/CN=www.example.org
   Subject Alternative Name: email: webmaster@example.org
   Certificate type:         Server certificate
   Form data:                Department the same, name Johnny Smith, phone 6666

 "
    }

OPTIND=1
while getopts "h?cun:k:pP:r:K:d:N:E:D:T:" opt; do
    case "$opt" in
    h|\?)
        usage ;
        exit 0
        ;;
    c)  type='Server-Client';
	exkeyusage='clientAuth, serverAuth';
	keyusage='digitalSignature, keyEncipherment,'
	keyusage='digitalSignature, keyEncipherment, dataEncipherment'
        ;;
    u)  type='User'
	exkeyusage='clientAuth, emailProtection, 1.3.6.1.4.1.311.20.2.2';
	keyusage='digitalSignature, keyEncipherment'
	echo USER mode
        ;;
    n)  type=$OPTARG;
	;;
    k)  keysize=$OPTARG;
        ;;
    K)  keyfile=$OPTARG;
        ;;
    d)  dn=$OPTARG
	;;
    p)  post=1
	;;
    r)  retrieve=$OPTARG;
	;;
    P)  requestfile=$OPTARG
	;;
    N)  formname="$OPTARG";
        ;;
    E)  formemail="$OPTARG";
        ;;
    D)  formdept="$OPTARG";
        ;;
    T)  formphone="$OPTARG";
        ;;
    esac
done

# parse operands
shift $((OPTIND-1))

# handle retrieval
# retrieval needs number and keyfile
if [[ $keyfile && ! -r $keyfile ]] ; then
    echo Can not use private key, $keyfile not found or not readable, aborted.
    exit 1;
elif [[ $retrieve && ! -s $keyfile ]] ; then
    echo Please provide a private key file using -K option for certificate retrieval '(-r)'.
    exit 1;
elif [[ $keyfile && -z $retrieve ]] ; then
    echo Please use -K only for certificate tertieval with -r.
    exit 1;
elif [[ $retrieve && ! -r $keyfile ]] ; then
    echo Please use -K to provide an existing private key matching with request.
    echo Retrieval of certificate without private key aborted.
    exit 1;
elif [[ $retrieve && -r $keyfile ]] ; then
    # attempt to process retrieval
    CAfile=/tmp/${BASHPID}-signet02cacert.crt
    curl --insecure http://signet-ca.ijs.si/pub/cacert/signet02cacert.crt > $CAfile
    if [[ -r $CAfile && -s $CAfile ]] ; then
	echo Downloaded SiGNET 02 CA file...
    else 
	echo Could not download SiGNET 02 CA certificate.
	echo Internet connectivity error? Aborting.
	exit 1
    fi
    # retrieve certificate
    p12file=`basename $keyfile .key`.p12
    certfile=`basename $keyfile .key`.crt
    #echo PROCESSING $CAfile $p12file $certfile $keyfile
    curl --insecure 'https://signet-ca.ijs.si:443/cgi-bin/pub/pki?cmd=getcert&key='$retrieve'&type=CERTIFICATE' > $certfile
    if [[ -r $CAfile && -s $CAfile ]] ; then
	echo Downloaded certificate $retrieve ...
    else 
	echo Could not download certificate $retrieve. Aborting.
	exit 1
    fi
    echo Creating browser-importable certificate file $p12file.
    echo Please provide encryption passphrase. You will use it to import the certificate.
    echo
    openssl pkcs12 -export -out $p12file -CAfile $CAfile -inkey $keyfile -in $certfile
    if [[ -r $p12file && -s $p12file ]] ; then
	echo Browser-importable certificate file $p12file created.
	echo
	echo Please import $p12file into your certificate
	echo as a private certificate backup.
	echo
	echo For use with NorduGrid ARC, please do:
	echo '  cp' $certfile ~/.arc/usercert.pem
	echo '  cp' $keyfile  ~/.arc/userkey.pem
	echo '  ch'mod 600    ~/.arc/userkey.pem
	exit 0
    else 
	echo Could not create the browser-importable certificate file $p12file.
	exit 1
    fi
fi 

    
# parse arguments
if [[ $requestfile && ! -r $requestfile ]] ; then
    echo Can open request file $requestfile for reading, aborted.
    exit 1;
elif [ $requestfile ] ; then
    dn=$(openssl req -in $requestfile -noout -subject)
    echo "Using preexisting request $requestfile with
  $dn."
    [[ $dn ]] || echo "Can't extract info from request file ${requestfile}
(check format), aborting"
    [[ $dn ]] || exit 1
    [[ $dn == *"subject=/C=SI/O=SiGNET/O="* ]] || echo "Can'f find distinghised name starting with 
  /C=SI/O=SiGNET/O= (canonical SiGNET CA namespace).
  Aborting."
    [[ $dn == *"subject=/C=SI/O=SiGNET/O="* ]] || exit 1
    CN=$(echo $dn | perl -ne'$cn = $1 if m{/CN=([^/=]+)}; END { print $cn }')
    EMAIL=$(echo $dn | perl -ne'$cn = $1 if m{/emailAddress=([^/=]+)}; END { print $cn }')
    OU=$(echo $dn | perl -ne'$cn = $1 if m{/OU=([^/=]+)}; END { print $cn }')
    OO=$(echo $dn | perl -ne'$cn = $1 if m{/C=SI/O=SiGNET/O=([^/=]+)}; END { print $cn }')
    echo "Subject info:
 O=$OO
 OU=$OU
 CN=$CN
 email=$EMAIL"
    post=1
elif [[ $dn && $dn != *"/C=SI/O=SiGNET/O="*  ]] ; then
    echo "Distinghised name specified, but does not include 
  /C=SI/O=SiGNET/O= (canonical SiGNET CA namespace).
  Aborting."
    usage
    exit 1
elif [ $dn ] ; then
    CN=$(echo $dn | perl -ne'$cn = $1 if m{/CN=([^/=]+)}; END { print $cn }')
    test "$CN" || echo 'Could not parse DN to get CN...'
    test "$CN" || usage 
    test "$CN" || exit 1
    EMAIL=$1
    test "$EMAIL" || echo 'Missing email argument...'
    test "$EMAIL" || usage 
    test "$EMAIL" || exit 1
else
    # default way
    echo Default...
    EMAIL=$1
    OO=$2
    OU=$3
    CN=$4
    test "$CN" || echo 'Not enough options (or mixed options and arguments) ...'
    test "$CN" || usage 
    test "$CN" || exit 1
    dn="/C=SI/O=SiGNET/O=${OO}/OU=${OU}/CN=${CN}"
fi

if [[ ! $requestfile ]]; then
    # generete request

    CONF=/tmp/${BASHPID}-signetreq.conf
    FILENAME=`echo $CN | tr  ':/;,. ' '----__'`
    KEY="$FILENAME"-$(date +%F).key
    CRS="$FILENAME"-$(date +%F).crs

    cat <<ENDFILE > $CONF
[req]
default_bits           = 2048
default_keyfile        = privatekey.pem
default_md	       = sha256
distinguished_name     = req_distinguished_name
attributes             = req_attributes
x509_extensions        = v3_req

[req_distinguished_name]
emailAddress			= Email Address
emailAddress_max		= 60
commonName			= Common Name (eg, YOUR name)
commonName_max			= 64
organizationalUnitName		= Organizational Unit Name (eg, section)
organizationalUnitName       	= Organizational Unit Name (eg, section)
organization                   	= Organizational Name (eg, company)
0.organizationName		= Organization Name
0.organizationName_default	= SiGNET
countryName			= Country Name (2 letter code)
countryName_default		= SI
countryName_min			= 2
countryName_max			= 2

[v3_req]
subjectKeyIdentifier   = hash
subjectAltName	       = email:copy
basicConstraints       = CA:FALSE
keyUsage 	       = $keyusage
nsComment	       = "$type Certificate Request of SiGNET CA"
extendedKeyUsage       = $exkeyusage
certificatePolicies    = 1.3.6.1.4.1.15312.3.1.1.0

[req_attributes]
SET-ex3		       = SET extension number 3
ENDFILE

    openssl req -config $CONF -reqexts v3_req -new \
	-sha256 -newkey rsa:$keysize -nodes \
        -subj "${dn}/emailAddress=${EMAIL}" \
	-keyout "$KEY" -out "$CRS"

    RES="$?"
    test "$RES" || rm -f "$KEY" "$CRS" "$CONF"
    test "$RES" || echo 'Aborting...'
    test "$RES" || $RES

    chmod o-rwx "$KEY"

    echo Generated $type certificate request "$CRS" and private key "$KEY" .
    rm $CONF
else
    # use preexisting request
    CRS=$requestfile
fi
    
# process the post
if [ $post -gt 0 ]
then
    echo "Posting request to $postform"
    CJAR=/tmp/${BASHPID}-cookies.jar
    RESP=/tmp/${BASHPID}-resp.html
    request=$(cat "$CRS");
    loa=''
    test "$formname"  || formname=$CN
    test "$formemail" || formemail=$EMAIL
    test "$formdept"  || formdept=$OU
    test "$formphone" || formphone='xxx'
    
    curl -k -c $CJAR 'https://signet-ca.ijs.si/cgi-bin/pub/pki?cmd=pkcs10_req&SRVR=0' > /dev/null
    curl -k -b $CJAR -e 'https://signet-ca.ijs.si/cgi-bin/pub/pki?cmd=pkcs10_req&SRVR=0' \
     -F "ADDITIONAL_ATTRIBUTE_DEPARTMENT=$formdept" \
     -F "loa=$formloa" \
     -F "ADDITIONAL_ATTRIBUTE_TELEPHONE=$formphone" \
     -F "cmd=pkcs10_req" \
     -F "passwd1=$pin" \
     -F "passwd2=$pin" \
     -F "ADDITIONAL_ATTRIBUTE_EMAIL=$formemail" \
     -F "ra=SiGNET" \
     -F "operation=server-confirmed-form" \
     -F "role=$type" \
     -F "ADDITIONAL_ATTRIBUTE_REQUESTERCN=$formname" \
     -F "request=$request" \
     'https://signet-ca.ijs.si/cgi-bin/pub/pki' \
    -o $RESP ;
    echo Finished.
    serial=$(perl -ne'$serial = $1 if m{serial ([0-9]+) .* successfully}; END { print $serial }' < "$RESP" )
    if [ $serial ]
    then
	echo "Posted request for $CN:
  pin:    $pin
  serial: $serial"
	rm "$RESP"
    else
	echo "Warning: request for $CN not posted (failure, output left in $RESP)."
    fi
fi

exit

# this was broken anyway...
# curl -k -b $CJAR -e 'https://signet-ca.ijs.si/cgi-bin/pub/pki?cmd=pkcs10_req&SRVR=0' \
# 	 -F "ra=SiGNET" -F "role=$type" \
# 	 -F passwd1=1234567890 -F passwd1=1234567890 \
# 	 -F "ADDITIONAL_ATTRIBUTE_REQUESTERCN=$formname" \
# 	 -F "ADDITIONAL_ATTRIBUTE_EMAIL=$formemail" \
# 	 -F "ADDITIONAL_ATTRIBUTE_DEPARTMENT=$formdept" \
# 	 -F "ADDITIONAL_ATTRIBUTE_TELEPHONE=$formphone" \
# 	 -F "operation=server-confirmed-form" -F "loa=$loa"\
# 	 -F "request=$request" \
# 	 $postform

