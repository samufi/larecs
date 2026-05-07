"""
The `_trace_function` helper prints nested `[IN]` and `[OUT]` markers without
timestamps. This script reconstructs the call stack and assigns synthetic
timestamps based on line order so the output can be visualized as slices in the
Perfetto UI.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from perfetto.protos.perfetto.trace.perfetto_trace_pb2 import TrackEvent
from perfetto.trace_builder.proto_builder import TraceProtoBuilder


TRACE_LINE_RE = re.compile(
    r"^\[(?P<direction>IN|OUT)\]\s*,\s*(?P<name>.+?)\s*,\s*(?P<timestamp>\d+)\s*ns\s*$"
)
TRACK_UUID = 1
TRUSTED_PACKET_SEQUENCE_ID = 1
DEFAULT_TRACK_NAME = "larecs::_trace_function"


@dataclass(frozen=True)
class TraceEvent:
    direction: str
    name: str
    line_number: int
    timestamp_ns: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert `_trace_function` log lines into a Perfetto trace."
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=Path,
        default=Path("query.log"),
        help="Path to the log file to convert.",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="Output Perfetto trace path. Defaults to the input stem with a .pftrace suffix.",
    )
    parser.add_argument(
        "--track-name",
        default=DEFAULT_TRACK_NAME,
        help="Track name shown in the Perfetto UI.",
    )
    return parser.parse_args()


def parse_trace_events(input_path: Path) -> list[TraceEvent]:
    events: list[TraceEvent] = []
    for line_number, raw_line in enumerate(input_path.read_text().splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue

        match = TRACE_LINE_RE.match(line)
        if match is None:
            raise ValueError(f"Unrecognized trace line at {input_path}:{line_number}: {raw_line}")

        events.append(
            TraceEvent(
                direction=match.group("direction"),
                name=match.group("name").strip(),
                line_number=line_number,
                timestamp_ns=int(match.group("timestamp")),
            )
        )

    return events


def add_packet(builder: TraceProtoBuilder):
    packet = builder.add_packet()
    packet.trusted_packet_sequence_id = TRUSTED_PACKET_SEQUENCE_ID
    return packet


def add_track_descriptor(builder: TraceProtoBuilder, track_name: str) -> None:
    packet = add_packet(builder)
    packet.track_descriptor.uuid = TRACK_UUID
    packet.track_descriptor.name = track_name


def add_slice_packet(
    builder: TraceProtoBuilder,
    *,
    timestamp_ns: int,
    event_type: int,
    name: str,
) -> None:
    packet = add_packet(builder)
    packet.timestamp = timestamp_ns
    packet.track_event.type = event_type
    packet.track_event.track_uuid = TRACK_UUID
    packet.track_event.name = name


def convert_trace_events(events: list[TraceEvent], track_name: str) -> TraceProtoBuilder:
    builder = TraceProtoBuilder()
    add_track_descriptor(builder, track_name)

    stack: list[TraceEvent] = []
    for event in events:
        if event.direction == "IN":
            stack.append(event)
            add_slice_packet(
                builder,
                timestamp_ns=event.timestamp_ns,
                event_type=TrackEvent.TYPE_SLICE_BEGIN,
                name=event.name,
            )
            continue

        if not stack:
            raise ValueError(
                f"Unmatched OUT event at line {event.line_number}: {event.name}"
            )

        start_event = stack.pop()
        if start_event.name != event.name:
            raise ValueError(
                "Trace stack mismatch at line "
                f"{event.line_number}: expected OUT {start_event.name!r}, "
                f"got {event.name!r}"
            )

        add_slice_packet(
            builder,
            timestamp_ns=event.timestamp_ns,
            event_type=TrackEvent.TYPE_SLICE_END,
            name=event.name,
        )

    if stack:
        print(
            f"Warning: {len(stack)} unclosed IN event(s) at EOF; closing implicitly.",
            file=sys.stderr,
        )

        warning_lines = [
            f"  - line {event.line_number}: {event.name}" for event in reversed(stack)
        ]
        print("\n".join(warning_lines), file=sys.stderr)

        # Use the last timestamp + 1 ns for implicitly closed events
        max_timestamp = max(e.timestamp_ns for e in events) if events else 0
        next_timestamp = max_timestamp + 1
        
        while stack:
            open_event = stack.pop()
            add_slice_packet(
                builder,
                timestamp_ns=next_timestamp,
                event_type=TrackEvent.TYPE_SLICE_END,
                name=open_event.name,
            )
            next_timestamp += 1

    return builder


def main() -> int:
    args = parse_args()

    if not args.input.exists():
        raise SystemExit(f"Input file not found: {args.input}")

    output_path = args.output or args.input.with_suffix(".pftrace")
    events = parse_trace_events(args.input)
    builder = convert_trace_events(events, args.track_name)

    output_path.write_bytes(builder.serialize())
    print(f"Wrote Perfetto trace to {output_path}")
    print("Open it in the Perfetto UI: https://ui.perfetto.dev/")
    return 0


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(exc)
        raise SystemExit(1)