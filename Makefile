start::
	sudo systemctl start foobar.target

stop::
	sudo systemctl stop foobar.target

reload::
	sudo rm -f /etc/systemd/system/foobar.target
	sudo rm -f /etc/systemd/system/foo.service
	sudo rm -f /etc/systemd/system/bar.service
	sudo ln -s $(PWD)/foobar.target /etc/systemd/system
	sudo ln -s $(PWD)/foo.service /etc/systemd/system
	sudo ln -s $(PWD)/bar.service /etc/systemd/system
	sudo systemctl daemon-reload
	sudo systemctl enable foo.service bar.service

log::
	journalctl -xe -u target -u foo -u bar
status::
	systemctl status foobar.target foo.service bar.service
