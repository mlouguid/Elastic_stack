#!/bin/bash

# Configuration
ELASTICSEARCH_HOST="localhost"
ELASTICSEARCH_PORT="9200"
USERNAME="elastic"
PASSWORD="LmoajdEd"
INDEX_PREFIX="mikrotik-"

# Nombre maximum d'index à conserver
MAX_INDICES=20


# Vérifier le nombre de répliques de l'index
REPLICA_COUNT=$(curl -s -u "$USERNAME:$PASSWORD" "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_all/_settings"  | grep -o '"number_of_replicas":"[0-9]*"' | head -n 1 | cut -d':' -f2 | tr -d '"')

# Si le nombre de répliques est supérieur à 0, ajustez le paramètre
if [[ $REPLICA_COUNT -gt 0 ]]; then
    curl -s -u "$USERNAME:$PASSWORD" -X PUT "http://$ELASTICSEARCH_HOST:9200/_all/_settings" -H "Content-Type: application/json" -d '{
      "index" : {
        "number_of_replicas" : 0
      }
    }'

    curl -s -u "$USERNAME:$PASSWORD" -X PUT "http://$ELASTICSEARCH_HOST:9200/_template/default_template" -H "Content-Type: application/json" -d '{
      "index_patterns" : ["*"],
      "settings" : {
        "number_of_replicas" : 0
      }
    }'
fi

# Supprimer les anciens index
indices=$(curl -s -u "$USERNAME:$PASSWORD" -X GET "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_cat/indices/$INDEX_PREFIX*" | awk '{print $3}' | sort)
count=$(echo "$indices" | wc -l)
echo $count ;
if [[ $count -gt $MAX_INDICES ]]; then
    indices_to_delete=$(echo "$indices" | head -n -$MAX_INDICES)
    for index in $indices_to_delete; do
        curl -s -u "$USERNAME:$PASSWORD" -X DELETE "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/$index"
        echo "Deleted index: $index"
    done
else
    echo "No indices to delete."
fi
