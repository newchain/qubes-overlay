subject /bin/bash odsAT {

	$shell_login | ( $nsswitch - $nsswitch_hide ) | $nsswitch_stfu | $shell_login_qfile_policy
}
