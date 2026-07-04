output "db_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "Connection host url for RDS PostgreSQL database"
}

output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "Endpoint address of the ElastiCache Redis cluster node"
}
