deploy:
	hexo generate
	rsync -av public root@101.37.89.10:/source/myblog

build:
	@docker build -t richardwei/myblog:0.05 .

run:
	@docker run -p 3003:3003 -d