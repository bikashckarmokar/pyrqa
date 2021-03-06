/*
This file is part of PyRQA.
Copyright 2015 Tobias Rawald, Mike Sips.
*/

__kernel void vertical(
    __global const float* time_series_x,
    __global const float* time_series_y,
    const uint dim_x,
    const uint dim_y,
    const uint m,
    const uint t,
    const float e,
    __global uint* recurrence_points,
    __global uint* vertical_frequency_distribution,
    __global uint* vertical_carryover,
    __global uint* white_vertical_frequency_distribution,
    __global uint* white_vertical_carryover,
    __global uchar* matrix
)
{
    uint global_id_x = get_global_id(0);

    if (global_id_x < dim_x)
    {
        uint t_x;
        uint t_y;
        float max;

        uint points = recurrence_points[global_id_x];
        uint vertical = vertical_carryover[global_id_x];
        uint white_vertical = white_vertical_carryover[global_id_x];

        for (uint global_id_y = 0; global_id_y < dim_y; ++global_id_y)
        {
            max = 0.0f;
            for (uint i = 0; i < m; ++i)
            {
                t_x = global_id_x + (i*t);
                t_y = global_id_y + (i*t);

                max = fmax(fabs(time_series_x[t_x] - time_series_y[t_y]), max);
            }

            if (max < e)
            {
                matrix[global_id_y * dim_x + global_id_x] = 1;
                points++;
                vertical++;

                if (white_vertical > 0)
                {
                    atomic_inc(&white_vertical_frequency_distribution[white_vertical - 1]);
                }

                white_vertical = 0;
            }
            else
            {
                matrix[global_id_y * dim_x + global_id_x] = 0;
                white_vertical++;

                if (vertical > 0)
                {
                    atomic_inc(&vertical_frequency_distribution[vertical - 1]);
                }

                vertical = 0;
            }
        }

        recurrence_points[global_id_x] = points;
        vertical_carryover[global_id_x] = vertical;
        white_vertical_carryover[global_id_x] = white_vertical;
    }
}
