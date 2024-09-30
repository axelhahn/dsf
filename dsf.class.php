<?php


class dsfproject {

    /**
     * Hash ofg al source projects and its targets
     * @var array
     */
    protected array $_aProfiles = [];

    /**
     * Hash of targets and their sources
     * @var array
     */
    protected array $_aTargets = [];

    /**
     * Constructor
     */
    public function __construct(){
        $this->_readConifigs();
    }
   


    /**
     * Read all configs written by bash and parse it
     * @return void
     */
    protected function _readConifigs(): void
    {
        $this->_aProfiles = [];
        $this->_aTargets = [];

        foreach( glob (__DIR__.'/profiles/*txt') as $sProfileConfig ){

            // read bash config file
            $s=file_get_contents($sProfileConfig);

            // parse config data
            preg_match_all('/^# PROFILE CONFIG - DSF v(.*)$/m', $s, $aVersion);
            preg_match_all('/^# CREATED(.*)$/m', $s, $aCreated);
            preg_match_all('/^SOURCE=(.*)$/m', $s, $aSource);
            preg_match_all('/^FILE=(.*)$/m', $s, $aFiles);
            preg_match_all('/^TARGET=(.*)$/m', $s, $aTargets);

            $sKey=basename($sProfileConfig,'.txt');

            // extend the list of profiles with the new one
            $this->_aProfiles[$sKey] = [
                '_file' => $sProfileConfig,
                'version' => $aVersion[1][0],
                'created' =>trim($aCreated[1][0]),
                'source' => $aSource[1][0],
                'files' => $aFiles[1],
                'targets' => $aTargets[1],
            ];

            // set/ extend an intenral list of targets
            foreach($aTargets[1] as $sTargetDir){
                if(!isset($this->_aTargets[$sTargetDir])) {
                    $this->_aTargets[$sTargetDir] = [];
                }
                $this->_aTargets[$sTargetDir][] = [
                    '_file' => $this->_aProfiles[$sKey]['_file'],
                    'source' => $this->_aProfiles[$sKey]['source'],
                ];

            }

        }
    }


    /**
     * Detect a current path in sources and return an array
     * Possible leys in return:
     *   - source_hit  direct hit of a source
     *   - source      hit of a source in a subdirectory
     *   - target_hit  direct hit of a target
     *   - target      hit of a target in a subdirectory
     * @return array|bool
     */
    public function detectCurrentPath(): array|bool{
        echo __METHOD__ . "\n";
        $aReturn=[];
        $sCurrentDir=getcwd();

        // loop over soource projects
        foreach ( $this->_aProfiles as $sKey => $aProfile ){
            echo $aProfile['source'] . "\n";
            if ( $aProfile['source'] === $sCurrentDir ){
                $aReturn['source_hit'] = $sKey;
            }
            if(strstr($aProfile['source'], $sCurrentDir)){
                $aReturn['source'] = $sKey;
            }
        }

        // loop over targets
        foreach($this->_aTargets as $sKey => $aTarget){
            $aVal=[
                $sKey => $aTarget
            ];
            if ( $sKey === $sCurrentDir ){
                $aReturn['target_hit'] = $aVal;
            }
            if(strstr($sKey, $sCurrentDir)){
                $aReturn['target'] = $aVal;
                break;
            }
        }
        return $aReturn;
    }

    /**
     * Just a debug function to print out all known profiles and targets
     * @return void
     */
    public function dump(){
        print_r($this->_aProfiles);
        print_r($this->_aTargets);
    }


    /**
     * Set the source directory for the given profile key
     * @param string $sKey Key of the profile
     * @return void
     */
    // public function setSource($sKey){
    //     $this->_aProfiles[$sKey]['source'] = getcwd();
    // }
}