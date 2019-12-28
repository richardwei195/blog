REMOTE_ADDRESS = root@111.230.200.127

deploy:
	hexo generate
	rsync -av public $(REMOTE_ADDRESS):/home/blog
