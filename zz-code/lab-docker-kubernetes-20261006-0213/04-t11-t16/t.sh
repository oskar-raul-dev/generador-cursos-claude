N="kubectl -n data exec nats-box -- nats -s nats://nats-ha.data:4222"
for i in 1 2 3; do $N pub -J a15.venta vt$i -H Nats-Msg-Id:t$i 2>&1 | tail -1; done
$N pub -J a15.venta vt1 -H Nats-Msg-Id:t1 2>&1|tail -1
time $N sub a15.venta --stream A15 --all --raw --count 3 2>&1 | tail -4
