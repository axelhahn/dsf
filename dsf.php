#!/usr/bin/php
<?php

$DSF_VERSION="0.13";
$DSF_VERSION="PHP-0.1";
require_once 'dsf.class.php';

// ----------------------------------------------------------------------
// FUNCTIONS
// ----------------------------------------------------------------------

function color(string $sColor){
    $aColors=[
        'reset' => '0',
        'head' => '33', // yellow
        'cmd' => '94', // light blue
        'input' => '92', // green
        'ok' => '92', // green
        'warning' => '33', // yellow
        'error' => '91', // red
        'h2' => '1;33', // yellow
        'h3' => '33', // yellow
        'key' => '04m\e[07', // reverse

    ];
    echo isset($aColors[$sColor])
        ?  "\033[".$aColors[$sColor]."m" 
        : "ERROR: $sColor\n"
        ;
}

function cecho($sColor, $sText){
    color($sColor);
    echo $sText;
    color("reset");
}

    /**
     * read user input with a given prefix
     * @param string $sPrefix prefix to show in front of the input
     * @param mixed $default value to return if the user does not enter anything
     * @return string the user entered string
     */

function input($sPrefix, $default = null) 
{    
    color('input', $sPrefix ? $sPrefix : '>');
    echo ' ';

    if (PHP_OS == 'WINNT') {
        $sReturn = stream_get_line(STDIN, 1024, PHP_EOL);
    } else {
        $sReturn = readline('');
    }
    return $sReturn ? $sReturn : $default;
}

// ----------------------------------------------------------------------
// MAIN
// ----------------------------------------------------------------------

$oSrc=new dsfproject();

// cecho("head", "HELLO");
color("cmd");
echo "_______________________________________________________________________________

 ▄▄▄▄    ▄▄▄▄  ▄▄▄▄▄   |
 █   ▀▄ █▀   ▀ █       |  DEPLOY
 █    █ ▀█▄▄▄  █▄▄▄▄   |    SOURCE                                       v$DSF_VERSION
 █    █     ▀█ █       |      FILES  ..  to multiple local targets
 █▄▄▄▀  ▀▄▄▄█▀ █       |
 
Axel Hahns helper tool to update local files in other projects.
_______________________________________________________________________________
";

color("reset");
echo "Current path: ".getcwd()."\n";



// $oSrc->dump(); die();

global $aHits;
$aHits=$oSrc->detectCurrentPath();
// print_r($aHits['source']);

function complete_source(){
    global $aHits;
    return array_values($aHits['source']);
}


readline_completion_function("complete_source");


// readline_completion_function(array_keys($aHits['source']));
$sSource=input("Source > ");
echo "DEBUG: sSource = $sSource\n";
