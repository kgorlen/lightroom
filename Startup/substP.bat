:MAP
subst P: \\NAS0\home\Pictures
if not exist P:\ (
	ping -n 6 127.0.0.1>nul
	goto MAP
)