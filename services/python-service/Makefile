.PHONY: install-chart put-params get-params

install-chart:
	helm upgrade --install python-service . -n digitalaurion-test --create-namespace -f values.yaml

put-params:
	aws ssm put-parameter --name /digitalaurion-test/python-service/DB_USER --type String --value "admin123" --overwrite
	aws ssm put-parameter --name /digitalaurion-test/python-service/DB_PASS --type String --value "123456" --overwrite
	aws ssm put-parameter --name /digitalaurion-test/python-service/API_ENDPOINT --type String --value "'https://api.sentienfi.com'" --overwrite
	aws ssm put-parameter --name /digitalaurion-test/python-service/FEATURE_FLAG --type String --value "true" --overwrite

get-params:
	aws ssm get-parameters --names /digitalaurion-test/python-service/DB_USER /digitalaurion-test/python-service/DB_PASS /digitalaurion-test/python-service/API_ENDPOINT /digitalaurion-test/python-service/FEATURE_FLAG --with-decryption
