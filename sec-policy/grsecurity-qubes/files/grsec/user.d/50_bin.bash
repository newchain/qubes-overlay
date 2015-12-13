subject /bin/bash odsAKT {

	$shell_login | ( $nsswitch - $nsswitch_hide ) | $nsswitch_stfu | $shell_login_user_policy
}
