all:
	sh ./install.sh

clean:
	k3d cluster delete
	@if [ -n "$$(docker ps -aq)" ]; then docker rm -f $$(docker ps -aq); fi
	docker system prune -a --volumes -f


