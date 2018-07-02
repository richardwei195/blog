REMOTE_ADDRESS = root@39.106.138.226

deploy:
	hexo generate
	rsync -av public $(REMOTE_ADDRESS):/source/myblog

dev_deploy:
	hexo generate
	rsync -av public $(REMOTE_ADDRESS):/source/dev

build:
	@docker build -t richardwei/myblog:0.05 .

run:
	@docker run -p 3003:3003 -d
