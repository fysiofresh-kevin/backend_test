export interface IInvoice {
  id: number;
  created_at: string;
  from: string;
  to: string;
  billwerk_id: string;
  dinero_id: string;
  status: string;
  change_log: string;
  subscription_id: string | number;
}

export interface IInvoiceWithOrderLines extends IInvoice {
  order_lines: {
    service: string;
    price: number;
    discount: number;
  }[];
}
