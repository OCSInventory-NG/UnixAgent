package Ocsinventory::Agent::Backend::OS::Generic::Screen;
use strict;
use utf8;

use Parse::EDID;

sub haveExternalUtils {
    my $common = shift;

    return $common->can_run("monitor-get-edid-using-vbe") || $common->can_run("monitor-get-edid") || $common->can_run("get-edid");
}

sub check {
    my $params = shift;
    my $common = $params->{common};

    return unless -d "/sys/devices" || haveExternalUtils($common);
    1;
}

sub _getManufacturerFromCode {
    my $code = shift;
    my $h = {
    "ACI" => "Ancor Communications", # ASUS
    "ACR" => "Acer America Corp.",
    "ACT" => "Targa",
    "ADI" => "ADI Corporation http://www.adi.com.tw",
    "ADT" => "Advantech",
    "AGN" => "AG Neovo",
    "AIC" => "Arnos Instruments", # AG Neovo
    "ALB" => "Alba",
    "ALC" => "Alches",
    "AMH" => "AMH",
    "AMI" => "Amitech",
    "AMR" => "JVC",
    "AMT" => "AMT International", # AMTRAN?
    "AMW" => "AMW",
    "AOC" => "AOC International (USA) Ltd.",
    "AOP" => "AOpen",
    "API" => "Acer America Corp.",
    "APP" => "Apple Computer, Inc.",
    "AQS" => "Aquarius",
    "ARG" => "Alba",
    "ARM" => "Armaggeddon",
    "ASB" => "Prestigio", # ASBIS
    "ASM" => "Aosiman",
    "ART" => "ArtMedia",
    "AST" => "AST Research",
    "AMW" => "AMW",
    "ATE" => "Megavision",
    "ATV" => "Ativa",
    "AUO" => "AU Optronics Corporation",
    "AVG" => "Avegant",
    "AXM" => "AXM",
    "BAL" => "Balance",
    "BBK" => "BBK",
    "BBY" => "Insignia",
    "BEK" => "Beko",
    "BKM" => "Beike",
    "BLS" => "BUBALUS",
    "BMM" => "Proview",
    "BNQ" => "BenQ",
    "BOE" => "BOE Display Technology",
    "BRA" => "Braview",
    "BSE" => "Bose",
    "BTC" => "RS",
    "BUF" => "Buffalo",
    "CAL" => "Albatron",
    "CAS" => "CASIO",
    "CCE" => "CCE",
    "CHH" => "Changhong Electric",
    "CIS" => "Cisco",
    "CLX" => "Claxan",
    "CMI" => "InnoLux Display",
    "CMN" => "Chimei Innolux",
    "CMO" => "Chi Mei Optoelectronics",
    "CND" => "CND",
    "COB" => "COBY",
    "COR" => "CPT", # Chunghwa Picture Tubes
    "COS" => "NVISION",
    "CPL" => "Compal Electronics, Inc. / ALFA",
    "CPQ" => "COMPAQ Computer Corp.",
    "CPT" => "Chunghwa Picture Tubes, Ltd.",
    "CTL" => "CTL",
    "CTX" => "CTX - Chuntex Electronic Co.",
    "CYS" => "Aosiman",
    "DEC" => "Digital Equipment Corporation",
    "DEL" => "Dell Computer Corp.",
    "DIC" => "Dinner",
    "DNS" => "DNS",
    "DON" => "DENON",
    "DOS" => "Dostyle",
    "DPC" => "Delta Electronics, Inc.",
    "DSG" => "DSGR",
    "DSL" => "DisplayLink",
    "DTB" => "DTEN Board",
    "DUS" => "VOXICON",
    "DVA" => "GE",
    "DVM" => "RoverScan",
    "DWE" => "Daewoo Telecom Ltd",
    "DXP" => "DEXP",
    "ECS" => "ELITEGROUP Computer Systems",
    "EGA" => "Elgato",
    "EHJ" => "Epson",
    "EIZ" => "EIZO",
    "ELE" => "Element",
    "ELO" => "Elo Touch",
    "ENC" => "EIZO",
    "ENM" => "ENMAR",
    "ENV" => "Envision Peripherals",
    "EPI" => "Envision Peripherals, Inc.",
    "EQD" => "EQD",
    "EST" => "Estecom",
    "EXN" => "Extron",
    "FAC" => "Yuraku",
    "FCM" => "Funai Electric Company of Taiwan",
    "FDR" => "Founder",
    "FLU" => "Fluid",
    "FSN" => "D&T",
    "FUJ" => "Fujitsu",
    "FUS" => "Fujitsu Siemens",
    "GAM" => "GAOMON",
    "GBA" => "GABA",
    "GBT" => "GIGABYTE",
    "GEC" => "Gechic",
    "GGF" => "Game Factor",
    "GMI" => "XGIMI",
    "GRN" => "Green House",
    "GRU" => "Grundig",
    "GSM" => "LG Electronics Inc. (GoldStar Technology, Inc.)",
    "GSV" => "G-Story",
    "GWD" => "GreenWood",
    "GWY" => "Gateway 2000",
    "HAI" => "Haier",
    "HAN" => "Cbox",
    "HAR" => "Haier",
    "HAT" => "Huion",
    "HCD" => "ViewSonic",
    "HCM" => "HCL",
    "HED" => "Hedy",
    "HEI" => "Hyundai Electronics Industries Co., Ltd.",
    "HII" => "Higer",
    "HIQ" => "Hyundai ImageQuest",
    "HIS" => "Hisense",
    "HIT" => "Hitachi",
    "HKC" => "HKC",
    "HRE" => "Haier",
    "HSD" => "Hannspree Inc",
    "HSG" => "Hannspree",
    "HSL" => "Hansol Electronics",
    "HVR" => "HVR", # VR Headsets
    "HWP" => "HP",
    "HPC" => "Erisson",
    "HPN" => "HP",
    "HRT" => "Hercules",
    "HSE" => "Hisense",
    "HSJ" => "Intehill",
    "HTC" => "Hitachi Ltd. / Nissei Sangyo America Ltd.",
    "HUG" => "Hugon",
    "HUN" => "Huion",
    "HUY" => "HUYINIUDA",
    "HWP" => "Hewlett Packard",
    "HWV" => "HUAWEI",
    "HXF" => "BlueCase",
    "HXV" => "iQual",
    "HYC" => "Pixio",
    "IBM" => "IBM PC Company",
    "ICB" => "Pixio",
    "ICL" => "Fujitsu ICL",
    "ICP" => "IC Power",
    "IFS" => "InFocus",
    "IGM" => "Videoseven",
    "IMP" => "Impression", # V7
    "INC" => "INCA",
    "INL" => "InnoLux Display",
    "INN" => "PRISM+",
    "INZ" => "Insignia",
    "IQT" => "Hyundai",
    "ITA" => "Easy Living",
    "ITR" => "INFOTRONIC",
    "IVM" => "Idek Iiyama North America, Inc.",
    "IVO" => "InfoVision",
    "JDI" => "Japan Display Inc.", 
    "JEN" => "Jean",
    "JVC" => "JVC",
    "JXC" => "JXC", # Shenzhen JingXingCheng
    "KFC" => "KFC Computek",
    "KDM" => "Korea Data Systems",
    "KIV" => "Kivi",
    "KMR" => "Kramer",
    "KGN" => "Kogan",
    "KOA" => "Konka",
    "KOS" => "KOIOS",
    "KTC" => "KTC",
    "LDL" => "LDLC",
    "LEN" => "Lenovo",
    "LGD" => "LG Display",
    "LGP" => "LG Philips",
    "LHC" => "Denver",
    "LKM" => "ADLAS / AZALEA",
    "LNK" => "LINK Technologies, Inc.",
    "LNX" => "Lanix",
    "LPL" => "LG Philips",
    "LRN" => "Doffler",
    "LTN" => "Lite-On",
    "MAC" => "MacroSilicon",
    "MAG" => "MAG InnoVision",
    "MAX" => "Belinea, Maxdata Computer GmbH",
    "MBB" => "MAIBENBEN",
    "MCE" => "Metz",
    "MEC" => "Medion Akoya",
    "MEI" => "Panasonic Comm. & Systems Co.",
    "MEK" => "MEK",
    "MEL" => "Mitsubishi Electronics",
    "MIR" => "Miro Computer Products AG",
    "MJI" => "Marantz",
    "MP_" => "Monoprice",
    "MPC" => "Monoprice",
    "MSC" => "Syscom",
    "MSH" => "Microsoft",
    "MSI" => "MSI",
    "MS_" => "Sony, Panasonic",
    "MST" => "MStar",
    "MTC" => "Mitac",
    "MTX" => "Matrox",
    "MUL" => "Multilaser",
    "MUS" => "Mecer",
    "MZI" => "Digital Vision",
    "NAN" => "NANAO",
    "NCI" => "NECCI",
    "NCP" => "PANDA", # Nanjing CEC Panda
    "NEC" => "NEC Technologies, Inc.",
    "NFC" => "NFREN",
    "NIK" => "Niko",
    "NLK" => "MStar",
    "NOA" => "NOA VISION",
    "NOK" => "Nokia",
    "NRC" => "AOC",
    "NSO" => "Neso",
    "NUG" => "NU",
    "NVD" => "Nvidia",
    "NVI" => "NVISION",
    "NVT" => "Novatek",
    "OCM" => "oCOSMO",
    "ONK" => "Onkyo",
    "ONN" => "ONN",
    "OPT" => "Optoma",
    "OQI" => "OPTIQUEST",
    "ORN" => "Orion",
    "OTM" => "Optoma",
    "OTS" => "AOC",
    "OTT" => "Ottagono",
    "OWC" => "OWC",
    "PBK" => "PCBANK",
    "PBN" => "Packard Bell",
    "PCK" => "SENSY",
    "PDC" => "Polaroid",
    "PEA" => "Pegatron",
    "PEB" => "Proview",
    "PEG" => "PEGA",
    "PER" => "Turbo-X",
    "PGE" => "GNR",
    "PGS" => "Princeton Graphic Systems",
    "PHL" => "Philips Consumer Electronics Co.",
    "PIO" => "Pioneer",
    "PKB" => "Packard Bell",
    "PKR" => "Parker",
    "PLC" => "Philco",
    "PLN" => "Planar",
    "PLT" => "PiLot",
    "PNR" => "Planar",
    "PNS" => "Pixio",
    "POS" => "Positivo Tecnologia S.A.",
    "PRE" => "Prestigio",
    "PRT" => "Princeton",
    "PTH" => "TVS",
    "PTS" => "ProView/EMC/PTS YakumoTFT17SL",
    "QBL" => "QBell",
    "QDS" => "Quanta Display",
    "QMX" => "Gericom",
    "QSM" => "Qushimei",
    "QUN" => "Lenovo",
    "RDS" => "KDS",
    "REC" => "Reconnect",
    "REG" => "Mobile Pixels",
    "REL" => "Relisys",
    "RJT" => "Ruijiang",
    "RKU" => "Roku",
    "ROL" => "Rolsen",
    "RUB" => "Rubin",
    "RZR" => "Razer",
    "SAM" => "Samsung",
    "SAN" => "Sanyo",
    "SCE" => "Sun",
    "SCN" => "Scanport",
    "SEE" => "SEEYOO",
    "SHP" => "Sharp",
    "SII" => "Skyworth",
    "SMC" => "Samtron",
    "SMI" => "Smile",
    "SNI" => "Siemens Nixdorf",
    "SNN" => "SUNNY",
    "SNY" => "Sony",
    "SPT" => "Sceptre Tech",
    "SPV" => "Sunplus",
    "SRC" => "Shamrock Technology",
    "SRD" => "Haier",
    "STC" => "Sampo",
    "STI" => "Semp Toshiba",
    "STN" => "Samtron",
    "STK" => "S2-Tek",
    "STP" => "Sceptre",
    "SUN" => "Sun",
    "SVA" => "SVA",
    "SVR" => "Sensics",
    "SYL" => "Sylvania",
    "SYN" => "Olevia",
    "SZM" => "Mitac",
    "TAR" => "Targa Visionary",
    "TAT" => "Tatung Co. of America, Inc.",
    "TCL" => "TCL",
    "TEO" => "TEO",
    "TEU" => "Relisys",
    "TLX" => "Tianma XM",
    "TNJ" => "Toppoly",
    "TOP" => "TopView",
    "TOS" => "Toshiba",
    "TPV" => "Top Victory",
    "TRL" => "Royal Inform",
    "TSB" => "Toshiba, Inc.",
    "UMC" => "UMC",
    "UNM" => "Unisys Corporation",
    "UPS" => "UpStar",
    "VBX" => "VirtualBox",
    "VES" => "Vestel Elektronik",
    "VIT" => "Vita",
    "VJK" => "HannStar",
    "VLV" => "Valve",
    "VSC" => "ViewSonic",
    "VSN" => "Videoseven",
    "VTK" => "Viotek",
    "WAC" => "Wacom",
    "WAM" => "Pixio",
    "WIM" => "Wimaxit",
    "WNX" => "Wincor Nixdorf",
    "WTC" => "Waytec",
    "XER" => "Xerox",
    "XMD" => "Xiaomi",
    "XMI" => "Mi",
    "XSC" => "Immer",
    "XVS" => "XVision",
    "XYE" => "Xiangye",
    "YAK" => "Yakumo",
    "YLT" => "Panasonic",
    "YMH" => "Yamaha",
    "ZCM" => "Zenith Data Systems",
    "ZRN" => "Zoran",
    "___" => "Targa" };
  
    return $h->{$code} if (exists ($h->{$code}) && $h->{$code});
    return "Unknown manufacturer code ".$code;
}

sub getEdid {
    my $raw_edid;
    my $port = $_[0];
  
  # Mandriva
    $raw_edid = `monitor-get-edid-using-vbe --port $port 2>/dev/null`;
  
    # Since monitor-edid 1.15, it's possible to retrieve EDID information
    # through DVI link but we need to use monitor-get-edid
    if (!$raw_edid) {
        $raw_edid = `monitor-get-edid --vbe-port $port 2>/dev/null`;
    }   
  
    if (!$raw_edid) {
        foreach (1..5) { # Sometime get-edid return an empty string...
            $raw_edid = `get-edid 2>/dev/null`;
            last if (length($raw_edid) == 128 || length($raw_edid) == 256);
        }
    }
    return unless (length($raw_edid) == 128 || length($raw_edid) == 256);
  
    return $raw_edid;
}

sub run {
    my $params = shift;
    my $common = $params->{common};
    my $logger = $params->{logger};

    my $raw_perl = 1;
    my $verbose;
    my $MonitorsDB;
    my $base64;
    my $uuencode;
  
    my %found;

    my @edid_list;
    # first check sysfs if there are edid entries
    for my $file(split(/\0/,`find /sys/devices -wholename '*/card*/edid' -print0`)) {
        open(my $sys_edid_fd,'<',$file);
        my $raw_edid = do { local $/; <$sys_edid_fd> };
        if (length($raw_edid) == 128 || length($raw_edid) == 256 ) {
            push @edid_list, $raw_edid;
        }
    }

    # if not fall back to the old method
    if (!@edid_list && haveExternalUtils($common)) {
        for my $port(0..20){
            my $raw_edid = getEdid($port);
            if ($raw_edid){
                if (length($raw_edid) == 128 || length($raw_edid) == 256) {
                    push @edid_list, $raw_edid;
                }
            }
        }
    }

    for my $raw_edid(@edid_list) {
        my $edid = parse_edid($raw_edid);
        if (my $err = check_parsed_edid($edid)) {
            $logger->debug("check failed: bad edid: $err");
        }
        my $caption = $edid->{monitor_name};
	$caption =~ s/[^ -~].*$//;
        my $description = $edid->{week}."/".$edid->{year};
        my $manufacturer = _getManufacturerFromCode($edid->{manufacturer_name});
        my $serial = $edid->{serial_number};
        if (!exists $found{$serial}) {
            $found{$serial} = 1;
 
            eval "use MIME::Base64;";
            $base64 = encode_base64($raw_edid) if !$@;
            if ($common->can_run("uuencode")) {
                chomp($uuencode = `echo $raw_edid|uuencode -`);
                if (!$base64) {
                    chomp($base64 = `echo $raw_edid|uuencode -m -`);
                }
            }
            $common->addMonitor ({
                BASE64 => $base64,
                CAPTION => $caption,
                DESCRIPTION => $description,
                MANUFACTURER => $manufacturer,
                SERIAL => $serial,
                UUENCODE => $uuencode,
            });
        }
    }
}
1;

