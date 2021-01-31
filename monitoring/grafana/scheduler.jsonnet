local simpledash = import 'monitoring/grafana/simpledash.libsonnet';

simpledash.dashboard(
  title='Scheduler',
  templates=[
    simpledash.template(
      name='instance_name',
      query='label_values(instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_queued:irate1m, instance_name)',
      label='Instance name',
      selectionStyle=simpledash.selectMultiple,
    ),
    // TODO: Make it possible to filter the dashboard by platform. This
    // doesn't work right now, as Grafana doesn't escape double quotes
    // in regex patterns properly.
    /*
    simpledash.template(
      name='platform',
      query='label_values(instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_queued:irate1m, platform)',
      label='Platform',
      selectionStyle=simpledash.selectMultiple,
    ),
    */
  ],
  aggregationPeriods=null,
  rows=[
    // How many tasks are being moved through the scheduler.
    simpledash.row(
      title='Task rate by stage transition',
      panels=[
        simpledash.graph(
          title='Nonexistent → Queued',
          width=1 / 4,
          stacking=simpledash.stackingEnabled,
          unit=simpledash.unitOperationsPerSecond,
          targets=[
            simpledash.graphTarget(
              expr='instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_queued:irate1m{instance_name=~"$instance_name"}',
              legendFormat='{{instance_name}} {{platform}}',
            ),
          ],
        ),
        simpledash.graph(
          title='Queued → Executing',
          width=1 / 4,
          stacking=simpledash.stackingEnabled,
          unit=simpledash.unitOperationsPerSecond,
          targets=[
            simpledash.graphTarget(
              expr='instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_executing:irate1m{instance_name=~"$instance_name"}',
              legendFormat='{{instance_name}} {{platform}}',
            ),
          ],
        ),
        simpledash.graph(
          title='Executing → Completed',
          width=1 / 4,
          stacking=simpledash.stackingEnabled,
          unit=simpledash.unitOperationsPerSecond,
          targets=[
            simpledash.graphTarget(
              expr='grpc_code_instance_name_platform_result:buildbarn_builder_in_memory_build_queue_tasks_completed:irate1m{instance_name=~"$instance_name"}',
              legendFormat='{{instance_name}} {{platform}} {{result}} {{grpc_code}}',
            ),
          ],
        ),
        simpledash.graph(
          title='Completed → Removed',
          width=1 / 4,
          stacking=simpledash.stackingEnabled,
          unit=simpledash.unitOperationsPerSecond,
          targets=[
            simpledash.graphTarget(
              expr='instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_removed:irate1m{instance_name=~"$instance_name"}',
              legendFormat='{{instance_name}} {{platform}}',
            ),
          ],
        ),
      ]
    ),

    // How many tasks are present within the scheduler.
    simpledash.row(
      title='Task count by stage',
      panels=[
        simpledash.graph(
          title=stage,
          width=1 / 3,
          stacking=simpledash.stackingEnabled,
          unit=simpledash.unitNone,
          targets=[
            simpledash.graphTarget(
              expr='instance_name_platform:buildbarn_builder_in_memory_build_queue_tasks_%s:sum{instance_name=~"$instance_name"}' % std.asciiLower(stage),
              legendFormat='{{instance_name}} {{platform}}',
            ),
          ],
        )
        for stage in ['Queued', 'Executing', 'Completed']
      ],
    ),

    // How long tasks spend within the scheduler.
    simpledash.row(
      title='Task duration by stage',
      panels=[
        simpledash.heatmap(
          title=stage,
          width=1 / 3,
          unit=simpledash.unitDurationSeconds,
          targets=[
            simpledash.heatmapTarget(
              expr='sum(instance_name_le_platform:buildbarn_builder_in_memory_build_queue_tasks_%s_duration_seconds_bucket:irate1m{instance_name=~"$instance_name"}) by (le)' % std.asciiLower(stage),
            ),
          ],
        )
        for stage in ['Queued', 'Executing', 'Completed']
      ],
    ),

    simpledash.row(
      title='Miscellaneous',
      panels=[
        simpledash.heatmap(
          title='Task execution retries',
          width=1,
          unit=simpledash.unitNone,
          targets=[
            simpledash.heatmapTarget(
              expr='sum(instance_name_le_platform:buildbarn_builder_in_memory_build_queue_tasks_executing_retries_bucket:irate1m{instance_name=~"$instance_name"}) by (le)',
            ),
          ],
        ),
      ],
    ),
  ],
)
