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

echo getcwd()."\n";
// $oSrc->dump();

print_r($oSrc->detectCurrentPath());
// echo "\033[31m H E L L O \033[0m\n";

// $oSrc->dump();
